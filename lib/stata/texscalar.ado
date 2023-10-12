program texscalar
	set more off
	
	* Parse arguments
	syntax anything using/, TEXNAME(string) [FMT(string) TAG(string)]
	tokenize `anything'
	
	if "`fmt'" == "" local fmt = "%-9.2fc"
	local fmtValue = strtrim(string(`1', "`fmt'"))

	*Write out.
	file open myfile using "`using'", write append
	
	*Use tag to store name of the .do file that calls the function
	di "Here is the `tag'"
	if "`tag'" != "" {
		file write myfile  _newline _newline  "% Set in: `tag'"	
	}
	
	file write myfile _newline _tab ///
			"\newcommand{\\`texname'math}{`fmtValue'}"
	file write myfile _newline _tab ///
			"\newcommand{\\`texname'text}{\textnormal{`fmtValue'}}"
	
	file close myfile
	set more on	
	
end
