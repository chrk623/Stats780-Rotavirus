%LET filepath = C:\Users\av3n1\Desktop\Stats 780;
%adminDatabaseMerge(filepath_to_databases = "C:\Users\av3n1\Desktop\Datasets For 780",
					   filepath_to_modules = "&filepath\Modules");

/* Year */
%createTableOfRates(denomFile = "&filepath\denomImport - Full.csv", 
	whichDenom = Year, 
	userCnd = (YEAR(EVSTDATE_&i) = INPUT(rowInfo.DenomSubTypeLabel, 4.0))
);

PROC EXPORT data = toReturn dbms = csv outfile = 'Year.csv' replace;
RUN;

%cleanTableOutput(tableOfRates = toReturn, by = Year);

/* Age Bands */
%createTableOfRates(denomFile = "&filepath\denomImport - Full.csv", 
	whichDenom = Age, 
	userCnd = (ageOfAdmission_&i BETWEEN LwrBnd AND UprBnd),
	AgeBandIgnore = "TRUE"
);

DATA toReturn;
	SET toReturn;
	IF RateString = ". (., .)" THEN RateString = " ";
PROC EXPORT data = toReturn dbms = csv outfile = 'Age.csv' replace;
RUN;

%cleanTableOutput(tableOfRates = toReturn, by = Age Band);

/* Ethnicity */
%createTableOfRates(denomFile = "&filepath\denomImport - Full.csv", 
	whichDenom = Ethnicity, 
	userCnd = (Ethnicity = rowInfo.DenomSubTypeLabel)
);

PROC EXPORT data = toReturn dbms = csv outfile = 'Ethnicity.csv' replace;
RUN;

%cleanTableOutput(tableOfRates = toReturn, by = Ethnicity);

/* Deprivation Index */
%createTableOfRates(denomFile = "&filepath\denomImport - Full.csv", 
	whichDenom = Deprivation Index, 
	userCnd = (Dep13 = INPUT(rowInfo.DenomSubTypeLabel, 2.0))
);

DATA toReturn;
	SET toReturn;
	DenomSubTypeLabel = INPUT(DenomSubTypeLabel, 2.0);
PROC EXPORT data = toReturn dbms = csv outfile = 'Deprivation.csv' replace;
RUN;

%cleanTableOutput(tableOfRates = toReturn, by = Deprivation Index);

/* District Health Board */
%createTableOfRates(denomFile = "&filepath\denomImport - Full.csv", 
	whichDenom = District Health Board, 
	userCnd = (DHBoard = rowInfo.DenomSubTypeLabel)
);

PROC EXPORT data = toReturn dbms = csv outfile = 'District.csv' replace;
RUN;

%cleanTableOutput(tableOfRates = toReturn, by = District Health Board);
