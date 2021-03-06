/^# Generated by/ {
	print "% " $0 "\n";
	print "-module(exmpp_known_elems).\n";
	print "-export([elem_as_list/1]).\n";
}

/^[^#]/ {
	if (!already_processed[$1]) {
		print "elem_as_list('" $1 "') ->\n    \"" $1 "\";";
		already_processed[$1] = 1;
	}
}

END {
	print "\nelem_as_list(Elem) when is_atom(Elem) ->";
	print "    atom_to_list(Elem);";
	print "elem_as_list(Elem) when is_list(Elem) ->\n    Elem.";
}
