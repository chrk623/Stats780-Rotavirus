%MACRO cleanTableOutput(tableOfRates, by, escapeChar = ^);
	ODS RTF file = "&by..rtf";
	ODS ESCAPECHAR = "&escapeChar";

	DATA toOutput;
		SET &tableOfRates (KEEP = DenomType DenomSubTypeLabel Event RateString);
	PROC SORT data = toOutput;
		BY DenomSubTypeLabel;
	PROC TRANSPOSE data = toOutput out = toOutput;
		BY DenomSubTypeLabel;
		VAR RateString;
		ID Event;
	PROC REPORT data = toOutput
		NOWD
		STYLE(report)=[rules = groups frame = below bordercolor = black]
	 	STYLE(header)=[background = _undef_ bordertopcolor = black just = l]; 

		COMPUTE BEFORE _PAGE_ / STYLE = [just = c font_weight = bold font_size = 4];
			LINE "Rates of Hospitalisation per 100,000 children aged 0 – 72 months old";
			LINE "by &by";
		ENDCOMP;

		COLUMN DenomSubTypeLabel Bronchiolitis Intussusception Rotavirus;
		DEFINE DenomSubTypeLabel / "&by";
		DEFINE Bronchiolitis/ "Bronchiolitis";
		DEFINE Intussusception / "Intussusception&escapeChar{super 1}";
		DEFINE Rotavirus / "Rotavirus";

		COMPUTE AFTER / STYLE = [just = l bordertopcolor = black font_size = 2];
			line "&escapeChar{super 1} Intussusception Rates are for children aged 0 – 36 months only.";
			line "Rates and their confidence intervals rounded to 0 decimal places.";
			line " ";
			line "Created %sysfunc(datetime(),datetime14.) by &filepath\%sysget(SAS_EXECFILENAME). SAS Version: &sysver";
		ENDCOMP; 
	RUN;

	PROC SQL NOPRINT;
		DROP TABLE toOutput;
	QUIT;

	ODS RTF CLOSE;
%MEND cleanTableOutput;
