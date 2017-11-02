/*==================================================================================*/
/* The macro function NHI_Module() creates a SAS database called NHI_base which has	*/
/* the following variables when used with the default arguments:					*/
/*	- master_hcu_id: A character variable.											*/
/*	- dob: A SAS date variable.														*/
/* 	- gender: A character variable.													*/
/*	- ethnicity: A character variable. 												*/
/*	- Dep13: A numeric variable.													*/
/*	- DHBoard: A character variable.												*/
/*																					*/
/* The macro function NHI_Module() has the following arguments:					 	*/
/*	- NHI_File: The name of the NHI SAS database. Default Value = Mis3090_cohort.	*/
/*																					*/
/* 	- primaryKey: The name of the column which contains a person's unique			*/
/*		identifier.	Default Value = master_hcu_id.									*/
/*	- dateOfBirth: The name of the column which contains a person's date of birth	*/
/*		entry in the NHI SAS database. Default Value = dob.							*/
/*	- gender: The name of the column which contains a person's gender entry in the	*/
/*		NHI SAS database. Default Value = gender.									*/
/*	- depIndex: The name of the column which contains a person's deprivation index	*/
/*		entry in the NHI SAS database. Default Value = Dep13.						*/
/*	- ethnicCode: The name of the column which contains a person's ethnicity entry	*/
/*		in the NHI SAS database. Default Value = ethnicgp.							*/
/*	- dhbCode: The name of the column which contains a person's district health		*/
/*		board entry in the NHI SAS database. Default Value = dhb_dom.				*/
/*																					*/
/*	- rsdntStatus: The name of the column which contains a person's residential 	*/
/*		status in New Zealand in the NHI SAS database.								*/
/*		Default Value = resident_status.											*/
/*	- rsdntFlag: The value which indicates that a person is a New Zealand resident. */
/*		Default Value = 'Y'.														*/
/*																					*/
/*	- dateOfDeath: The name of the column which contains a person's date of death	*/
/*		entry in the the NHI SAS database. Default Value = dod.						*/
/*																					*/
/*	- yrBegin & yrEnd: The range of birth years which captures the cohort of 		*/
/*		interest. Default Values: yrBegin = 2006; yrEnd = 2015.						*/
/*																					*/
/*==================================================================================*/

%MACRO NHI_Module(NHI_File = Bp9P2J.Mis3090_cohort,
		primaryKey = master_hcu_id, dateOfBirth = dob, gender = gender, depIndex = Dep13, ethnicCode = ethnicgp, dhbCode = dhb_dom,
		rsdntStatus = resident_status, rsdntFlag = 'Y', 
		dateOfDeath = dod, 
		yrBegin = 2006, yrEnd = 2015
	);

	DATA NHI_base;
		SET &NHI_File;
		LENGTH ethnicity $24. DHBoard $24.; 
		KEEP &primaryKey &dateOfBirth &gender ethnicity &depIndex DHBoard;

		/* 
			Create a cohort from the NHI which meet the following conditions:
				- Those who are NZ residents.
				- Those who were born between &yrBegin and &yrEnd.
				- Those who did not pass away on their date of birth.
		*/
		IF &rsdntStatus = &rsdntFlag AND &dateOfBirth ^= &dateOfDeath AND &yrBegin <= YEAR(&dateOfBirth) <= &yrEnd;

		/* 
			Recode ethnicgp to the ethnicity groups defined by the denominator information file:
				10, 11, 12, 51, 52, 53, 54, 61, 94, 95, 97, 99	-> NZEO.
				21												-> Maori.
				30, 31, 32, 33, 34, 35, 36, 37					-> Pacific Islander.
				40, 41, 42, 43, 44								-> Asian.
		*/
		IF 10 <= &ethnicCode <= 12 OR 51 <= &ethnicCode <= 99 THEN ethnicity = 'NZEO';
		IF &ethnicCode = 21 THEN ethnicity = 'Maori';
		IF 30 <= &ethnicCode <= 37 THEN ethnicity = 'Pacific Islander';
		IF 40 <= &ethnicCode <= 44 THEN ethnicity = 'Asian';

		/* 
			Recode missing values in dhb_dom to SAS missing values.
		*/
		IF &dhbCode = 'XXX' THEN &dhbCode = ' ';

		/* 
			Recode dhb_dom to their actual name of the dhb as defined by:
			http://www.health.govt.nz/nz-health-statistics/data-references/code-tables/common-code-tables/district-health-board-code-table 
		*/
		IF &dhbCode = '011' THEN DHBoard = 'Northland';
		IF &dhbCode = '021' THEN DHBoard = 'Waitemata';
		IF &dhbCode = '022' THEN DHBoard = 'Auckland';
		IF &dhbCode = '023' THEN DHBoard = 'Counties Manukau';
		IF &dhbCode = '031' THEN DHBoard = 'Waikato';
		IF &dhbCode = '042' THEN DHBoard = 'Lakes';
		IF &dhbCode = '047' THEN DHBoard = 'Bay of Plenty';
		IF &dhbCode = '051' THEN DHBoard = 'Tairawhiti';
		IF &dhbCode = '061' THEN DHBoard = "Hawke's Bay";
		IF &dhbCode = '071' THEN DHBoard = 'Taranaki';
		IF &dhbCode = '081' THEN DHBoard = 'Midcentral';
		IF &dhbCode = '082' THEN DHBoard = 'Whanganui';
		IF &dhbCode = '091' THEN DHBoard = 'Capital and Coast';
		IF &dhbCode = '092' THEN DHBoard = 'Hutt';
		IF &dhbCode = '093' THEN DHBoard = 'Wairarapa';
		IF &dhbCode = '101' THEN DHBoard = 'Nelson Marlborough'; 
		IF &dhbCode = '111' THEN DHBoard = 'West Coast';
		IF &dhbCode = '121' THEN DHBoard = 'Canterbury';
		IF &dhbCode = '123' THEN DHBoard = 'South Canterbury';
		IF &dhbCode = '160' THEN DHBoard = 'Southern';
		/*
			If their dhb_dom is '999' (Overseas) we want to exclude them from the cohort of interest.
		*/
		IF &dhbCode = '999' THEN DELETE;

	/* 
		Sort the data by &primaryKey and utilises the SORT procedure to delete complete duplicates from the cohort of interest.
	*/
	PROC SORT NODUP DATA = NHI_base; 
		BY &primaryKey; 
	RUN;

%MEND NHI_Module;
