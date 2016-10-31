(***************************************************)
(*                                                 *)
(*                        Main                     *)
(*                                                 *)
(*                  Caterina Urban                 *)
(*     École Normale Supérieure, Paris, France     *)
(*                   2012 - 2015                   *)
(*                                                 *)
(***************************************************)

(* parsing *)

let analysis = ref "termination"
let domain = ref "boxes"
let filename = ref ""
let fmt = ref Format.std_formatter
let main = ref "main"
let minimal = ref false
let ordinals = ref false
let property = ref ""
let time = ref false

let parseFile filename =
	let f = open_in filename in
	let lex = Lexing.from_channel f in
	try
		lex.Lexing.lex_curr_p <- { lex.Lexing.lex_curr_p
			with Lexing.pos_fname = filename; };
		let r = Parser.file Lexer.start lex in
		close_in f; r
	with
	| Parser.Error ->
		Printf.eprintf "Parse Error (Invalid Syntax) near %s\n"
			(IntermediateSyntax.position_tostring lex.Lexing.lex_start_p);
		failwith "Parse Error"
	| Failure "lexing: empty token" ->
		Printf.eprintf "Parse Error (Invalid Token) near %s\n"
			(IntermediateSyntax.position_tostring lex.Lexing.lex_start_p);
		failwith "Parse Error"

let parseProperty filename =
	let f = open_in filename in
	let lex = Lexing.from_channel f in
	try
		lex.Lexing.lex_curr_p <- { lex.Lexing.lex_curr_p
			with Lexing.pos_fname = filename; };
		let r = PropertyParser.file PropertyLexer.start lex in
		close_in f; r
	with
	| Parser.Error ->
		Printf.eprintf "Parse Error (Invalid Syntax) near %s\n"
			 (IntermediateSyntax.position_tostring lex.Lexing.lex_start_p);
		failwith "Parse Error"
	| Failure "lexing: empty token" ->
		Printf.eprintf "Parse Error (Invalid Token) near %s\n"
			 (IntermediateSyntax.position_tostring lex.Lexing.lex_start_p);
		failwith "Parse Error"

let parse_args () =
	let rec doit args =
		match args with
		| "-domain"::x::r -> (* abstract domain: boxes|octagons|polyhedra *)
			domain := x; doit r
		| "-guarantee"::x::r -> (* guarantee analysis *)
			analysis := "guarantee"; property := x; doit r
		| "-joinfwd"::x::r -> (* widening delay in forward analysis *)
			Iterator.joinfwd := int_of_string x; doit r
		| "-joinbwd"::x::r -> (* widening delay in backward analysis *)
			Iterator.joinbwd := int_of_string x; doit r
		| "-main"::x::r -> (* analyzer entry point *) main := x; doit r
		| "-meetbwd"::x::r -> (* dual widening delay in backward analysis *)
			Iterator.meetbwd := int_of_string x; doit r
		| "-minimal"::r -> (* analysis result only *)
			minimal := true; Iterator.minimal := true; doit r
		| "-ordinals"::x::r -> (* ordinal-valued ranking functions *)
			ordinals := true; Ordinals.max := int_of_string x; doit r
		| "-recurrence"::x::r -> (* recurrence analysis *)
			analysis := "recurrence"; property := x; doit r
		| "-refine"::r -> (* refine in backward analysis *)
			Iterator.refine := true; doit r
		| "-retrybwd"::x::r ->
			Iterator.retrybwd := int_of_string x;
			DecisionTree.retrybwd := int_of_string x;
			doit r
		| "-time"::r -> (* track analysis time *)
			time := true; doit r
		| "-timebwd"::r -> (* track backward analysis time *)
			Iterator.timebwd := true; doit r
		| "-timefwd"::r -> (* track forward analysis time *)
			Iterator.timefwd := true; doit r
		| "-timeout"::x::r -> (* analysis timeout *)
			Iterator.timeout := float_of_string x; doit r
		| "-tracebwd"::r -> (* backward analysis trace *)
			Iterator.tracebwd := true;
			DecisionTree.tracebwd := true;
			doit r
		| "-tracefwd"::r -> (* forward analysis trace *)
			Iterator.tracefwd := true; doit r
		| x::r -> filename := x; doit r
		| [] -> ()
	in
	doit (List.tl (Array.to_list Sys.argv))

(* do all *)

module TerminationBoxes =
	TerminationIterator.TerminationIterator(DecisionTree.TSAB)
module TerminationBoxesOrdinals =
	TerminationIterator.TerminationIterator(DecisionTree.TSOB)
module TerminationOctagons =
	TerminationIterator.TerminationIterator(DecisionTree.TSAO)
module TerminationOctagonsOrdinals =
	TerminationIterator.TerminationIterator(DecisionTree.TSOO)
module TerminationPolyhedra =
	TerminationIterator.TerminationIterator(DecisionTree.TSAP)
module TerminationPolyhedraOrdinals =
	TerminationIterator.TerminationIterator(DecisionTree.TSOP)

let result = ref false

let termination () =
	if !filename = "" then raise (Invalid_argument "No Source File Specified");
	let sources = parseFile !filename in
	let (program,_) = ItoA.prog_itoa sources in
	if not !minimal then
		begin
			Format.fprintf !fmt "\nAbstract Syntax:\n";
			AbstractSyntax.prog_print !fmt program;
		end;
	try
		match !domain with
		| "boxes" ->
			let start = Sys.time () in
			let terminating = if not !ordinals
				then TerminationBoxes.analyze program !main
				else TerminationBoxesOrdinals.analyze program !main
			in
			let stop = Sys.time () in
			Format.fprintf !fmt "Analysis Result: ";
			let result = if terminating then "TRUE" else "UNKNOWN" in
			Format.fprintf !fmt "%s\n" result;
			if !time then
				Format.fprintf !fmt "Time: %f s\n" (stop-.start);
			Format.fprintf !fmt "\nDone.\n"
		| "octagons" ->
			let start = Sys.time () in
			let terminating = if not !ordinals
				then TerminationOctagons.analyze program !main
				else TerminationOctagonsOrdinals.analyze program !main
			in
			let stop = Sys.time () in
			Format.fprintf !fmt "Analysis Result: ";
			let result = if terminating then "TRUE" else "UNKNOWN" in
			Format.fprintf !fmt "%s\n" result;
			if !time then
				Format.fprintf !fmt "Time: %f s\n" (stop-.start);
			Format.fprintf !fmt "\nDone.\n"
		| "polyhedra" ->
			let start = Sys.time () in
			let terminating = if not !ordinals
				then TerminationPolyhedra.analyze program !main
				else TerminationPolyhedraOrdinals.analyze program !main
			in
			let stop = Sys.time () in
			Format.fprintf !fmt "Analysis Result: ";
			let result = if terminating then "TRUE" else "UNKNOWN" in
			Format.fprintf !fmt "%s\n" result;
			if !time then
				Format.fprintf !fmt "Time: %f s\n" (stop-.start);
			Format.fprintf !fmt "\nDone.\n"
		| _ -> raise (Invalid_argument "Unknown Abstract Domain")
	with
	| Iterator.Timeout ->
		Format.fprintf !fmt "\nThe Analysis Timed Out!\n";
		Format.fprintf !fmt "\nDone.\n"

module GuaranteeBoxes =
	GuaranteeIterator.GuaranteeIterator(DecisionTree.TSAB)
module GuaranteeBoxesOrdinals =
	GuaranteeIterator.GuaranteeIterator(DecisionTree.TSOB)
module GuaranteeOctagons =
	GuaranteeIterator.GuaranteeIterator(DecisionTree.TSAO)
module GuaranteeOctagonsOrdinals =
	GuaranteeIterator.GuaranteeIterator(DecisionTree.TSOO)
module GuaranteePolyhedra =
	GuaranteeIterator.GuaranteeIterator(DecisionTree.TSAP)
module GuaranteePolyhedraOrdinals =
	GuaranteeIterator.GuaranteeIterator(DecisionTree.TSOP)

let guarantee () =
	if !filename = "" then raise (Invalid_argument "No Source File Specified");
	if !property = "" then raise (Invalid_argument "No Property File Specified");
	let sources = parseFile !filename in
	let property = parseProperty !property in
	let (program,property) =
		ItoA.prog_itoa ~property:(!main,property) sources in
	let property =
		match property with
		| None -> raise (Invalid_argument "Unknown Property")
		| Some property -> property
	in
	if not !minimal then
		begin
			Format.fprintf !fmt "\nAbstract Syntax:\n";
			AbstractSyntax.prog_print !fmt program;
			Format.fprintf !fmt "\nProperty: ";
			AbstractSyntax.property_print !fmt property;
		end;
	try
		match !domain with
		| "boxes" ->
			let start = Sys.time () in
			let eventually = if not !ordinals
				then GuaranteeBoxes.analyze property program !main
				else GuaranteeBoxesOrdinals.analyze property program !main
			in
			let stop = Sys.time () in
			Format.fprintf !fmt "Analysis Result: ";
			let result = if eventually then "TRUE" else "UNKNOWN" in
			Format.fprintf !fmt "%s\n" result;
			if !time then
				Format.fprintf !fmt "Time: %f s\n" (stop-.start);
			Format.fprintf !fmt "\nDone.\n"
		| "octagons" ->
			let start = Sys.time () in
			let eventually = if not !ordinals
				then GuaranteeOctagons.analyze property program !main
				else GuaranteeOctagonsOrdinals.analyze property program !main
			in
			let stop = Sys.time () in
			Format.fprintf !fmt "Analysis Result: ";
			let result = if eventually then "TRUE" else "UNKNOWN" in
			Format.fprintf !fmt "%s\n" result;
			if !time then
				Format.fprintf !fmt "Time: %f s\n" (stop-.start);
			Format.fprintf !fmt "\nDone.\n"
		| "polyhedra" ->
			let start = Sys.time () in
			let eventually = if not !ordinals
				then GuaranteePolyhedra.analyze property program !main
				else GuaranteePolyhedraOrdinals.analyze property program !main
			in
			let stop = Sys.time () in
			Format.fprintf !fmt "Analysis Result: ";
			let result = if eventually then "TRUE" else "UNKNOWN" in
			Format.fprintf !fmt "%s\n" result;
			if !time then
				Format.fprintf !fmt "Time: %f s\n" (stop-.start);
			Format.fprintf !fmt "\nDone.\n"
		| _ -> raise (Invalid_argument "Unknown Abstract Domain")
	with
	| Iterator.Timeout -> 
		Format.fprintf !fmt "\nThe Analysis Timed Out!\n"; 
		Format.fprintf !fmt "\nDone.\n"

module RecurrenceBoxes =
	RecurrenceIterator.RecurrenceIterator(DecisionTree.TSAB)
module RecurrenceBoxesOrdinals =
	RecurrenceIterator.RecurrenceIterator(DecisionTree.TSOB)
module RecurrenceOctagons =
	RecurrenceIterator.RecurrenceIterator(DecisionTree.TSAO)
module RecurrenceOctagonsOrdinals =
	RecurrenceIterator.RecurrenceIterator(DecisionTree.TSOO)
module RecurrencePolyhedra =
	RecurrenceIterator.RecurrenceIterator(DecisionTree.TSAP)
module RecurrencePolyhedraOrdinals =
	RecurrenceIterator.RecurrenceIterator(DecisionTree.TSOP)

let recurrence () =
	if !filename = "" then raise (Invalid_argument "No Source File Specified");
	if !property = "" then raise (Invalid_argument "No Property File Specified");
	let sources = parseFile !filename in
	let property = parseProperty !property in
	let (program,property) =
		ItoA.prog_itoa ~property:(!main,property) sources in
	let property =
		match property with
		| None -> raise (Invalid_argument "Unknown Property")
		| Some property -> property
	in
	if not !minimal then
		begin
			Format.fprintf !fmt "\nAbstract Syntax:\n";
			AbstractSyntax.prog_print !fmt program;
			Format.fprintf !fmt "\nProperty: ";
			AbstractSyntax.property_print !fmt property;
		end;
	try
		match !domain with
		| "boxes" ->
			let start = Sys.time () in
			let eventually = if not !ordinals
				then RecurrenceBoxes.analyze property program !main
				else RecurrenceBoxesOrdinals.analyze property program !main
			in
			let stop = Sys.time () in
			Format.fprintf !fmt "Analysis Result: ";
			let result = if eventually then "TRUE" else "UNKNOWN" in
			Format.fprintf !fmt "%s\n" result;
			if !time then
				Format.fprintf !fmt "Time: %f s\n" (stop-.start);
			Format.fprintf !fmt "\nDone.\n"
		| "octagons" ->
			let start = Sys.time () in
			let eventually = if not !ordinals
				then RecurrenceOctagons.analyze property program !main
				else RecurrenceOctagonsOrdinals.analyze property program !main
			in
			let stop = Sys.time () in
			Format.fprintf !fmt "Analysis Result: ";
			let result = if eventually then "TRUE" else "UNKNOWN" in
			Format.fprintf !fmt "%s\n" result;
			if !time then
				Format.fprintf !fmt "Time: %f s\n" (stop-.start);
			Format.fprintf !fmt "\nDone.\n"
		| "polyhedra" ->
			let start = Sys.time () in
			let eventually = if not !ordinals
				then RecurrencePolyhedra.analyze property program !main
				else RecurrencePolyhedraOrdinals.analyze property program !main
			in
			let stop = Sys.time () in
			Format.fprintf !fmt "Analysis Result: ";
			let result = if eventually then "TRUE" else "UNKNOWN" in
			Format.fprintf !fmt "%s\n" result;
			if !time then
				Format.fprintf !fmt "Time: %f s\n" (stop-.start);
			Format.fprintf !fmt "\nDone.\n"
		| _ -> raise (Invalid_argument "Unknown Abstract Domain")
	with
	| Iterator.Timeout -> 
		Format.fprintf !fmt "\nThe Analysis Timed Out!\n"; 
		Format.fprintf !fmt "\nDone.\n"

let doit () =
	parse_args ();
	match !analysis with
	| "termination" -> termination ()
	| "guarantee" -> guarantee ()
	| "recurrence" -> recurrence ()
	| _ -> raise (Invalid_argument "Unknown Analysis")

let _ = doit ()