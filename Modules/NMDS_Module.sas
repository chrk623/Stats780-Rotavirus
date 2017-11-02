/*==================================================================================*/
/* The macro function NMDS_Module() produces a SAS database called NMDS_Transpose.	*/
/* NMDS_Transpose contains the following columns with the default arguments:		*/
/*	- numOfHosEntries																*/
/*	- EVENT_ID_<i>																	*/
/*	- EVSTDATE_<i>																	*/
/*	- EVENDATE_<i>																	*/
/*	- event_<i>																		*/
/*	- clin_cd_<i>																	*/
/*	- ageOfAdmission_<i>															*/
/*	- MASTER_HCU_ID																	*/
/* where <i> corresponds to the ith NMDS entry.										*/
/*																					*/
/* The macro function NMDS_Module() also produces the following macro variables:	*/
/* - &NMDS_numOfEntries: The total number of distinct NMDS entries.					*/
/* - &NMDS_notInCohort_count: The number of entries which were dropped because they */
/*		were not in the NHI cohort of interest.										*/
/* - &NMDS_repeat_count: The number of entries dropped due to being in an exclusion	*/
/*		period which accounts for repeated hospitalisations.						*/
/*																					*/
/* The macro function NMDS_Module() has the following arguments:					*/
/*	- NHI_File: The name of the NHI SAS database.									*/
/*		Default Value = Bp9P2J.Mis3090_cohort.										*/
/*	- NMDS_events_file: The name of the NMDS Events SAS database.					*/
/*		Default Value = Bp9P2J.Pus9608_events.										*/
/*	- NMDS_diags_file: The name of the NMDS Diagnoses SAS database.					*/
/*		Default Value = Bp9P2J.Pus9608_diags.										*/
/*																					*/
/*	- primaryKey: The name of the column which contains a person's unique			*/ 
/*		identifier in NHI_File, NMDS_events_file, and NMDS_diags_file.				*/
/*		Default Value = MASTER_HCU_ID.												*/
/*	- dateOfBirth: The name of the column which contains a person's date of	birth	*/
/*		entry in NHI_File. Default Value = DOB.										*/
/*																					*/
/*	- eventID: The name of the column which contains an entry's	unique identifier	*/
/*		in the NMDS_events_file. Default Value = EVENT_ID.			  				*/
/*	- admssnDate: The name of the column which contains an entry's admission date	*/
/*		in the NMDS_events_file. Default Value = EVSTDATE.							*/
/*	- dschrgDate: The name of the column which contains an entry's discharge date	*/
/*		in the NMDS_events_file. Default Value = EVENDATE.							*/
/*																					*/
/*	- icdCode: The name of the column which contains an entry's ICD codes in the	*/
/*		NMDS_diags_file. Default Value = clin_cd.									*/
/*	- icdType: The name of the column which contains an entry's ICD system edition	*/
/*		in the NMDS_diags_file. Default Value = CLIN_SYS.							*/
/*	- diagsType: The name of the column which contains an entry's diagnosis type	*/
/*		in the NMDS_diags_file. Default Value = DIAG_TYP.							*/
/*	- diagsTypeFlag: Which type of diagnosis information do we want to extract from	*/
/*		the NMDS_diags_file. Default Value = "A".									*/
/*																					*/
/*	- rotavirusCodes: The ICD codes which correspond to rotavirus diagnoses in the	*/
/*		NMDS_diags_file. 															*/
/*		Default Value = ('A080', 'A082', 'A083', 'A084', 'A09', 'A090', 'A099').	*/
/*	- rotavirusLabel: The label to input into event_<i> for the rotavirus ICD 		*/
/*		codes. Default Value = 'Rotavirus'.											*/
/*																					*/
/*	- intussusceptionCodes: The ICD codes which correspond to intussusception 		*/
/*		diagnoses in the NMDS_diags_file. Default Value = ('K561').					*/
/*	- intussusceptionLabel: The label to input into event_<i> for the 				*/
/*		intussusception ICD codes. Default Value = 'Intussusception'.				*/
/*																					*/
/*	- bronchiolitisCodes: The ICD codes which correspond to bronchiolitis 			*/
/*		diagnoses in the NMDS_diags_file. Default Value = ('J210', 'J218', 'J219').	*/
/*	- bronchiolitisLabel: The label to input into event_<i> for the bronchiolitis	*/
/*		ICD codes. Default Value = 'Bronchiolitis'.									*/
/*																					*/
/*	- exlcusionDays: The number of days to exclude NMDS entries fpr once an NMDS 	*/
/*		entry has been observed. Default Value: 14.									*/
/*																					*/
/*==================================================================================*/

%MACRO NMDS_Module(NHI_File = Bp9P2J.Mis3090_cohort, NMDS_events_file = Bp9P2J.Pus9608_events, NMDS_diags_file = Bp9P2J.Pus9608_diags,
	primaryKey = MASTER_HCU_ID, dateOfBirth = DOB,
	eventID = EVENT_ID, admssnDate = EVSTDATE, dschrgDate = EVENDATE,
	icdCode = clin_cd, icdType = CLIN_SYS, diagsType = DIAG_TYP, diagsTypeFlag = "A", 
	rotavirusCodes = ('A080', 'A082', 'A083', 'A084', 'A09', 'A090', 'A099'), rotavirusLabel = 'Rotavirus',
	intussusceptionCodes = ('K561'), intussusceptionLabel = 'Intussusception',
	bronchiolitisCodes = ('J210', 'J218', 'J219'), bronchiolitisLabel = 'Bronchiolitis',
	exclusionDays = 14);

	PROC SQL NOPRINT;
		/* 
			Create a table with unique NHI entries and select the &primaryKey and &dateOfBirth variables.
		*/
		CREATE TABLE RVirus_NHI AS
		SELECT DISTINCT &primaryKey, 
	                    &dateOfBirth
		FROM &NHI_File
		ORDER BY &primaryKey;

		/* 
			Create a table with unique NMDS_Event entries and select the &primaryKey, &eventID, &admssnDate,
			and &dschrgDate variables.
		*/
		CREATE TABLE RVirus_NMDS_E AS
		SELECT DISTINCT &primaryKey,
						&eventID,
						&admssnDate,
						&dschrgDate
		FROM &NMDS_events_file;

		/* 
			Merge the NMDS_Event table onto the NHI table by &primaryKey. Note that we only select unique NMDS_Event entries 
			from the merged table. The type of merge is a LEFT JOIN and the WHERE part of the call ensures that 
			we will only select NMDS_Event entries for &primaryKeys in the NHI table.
		*/
		CREATE TABLE NMDS_Base AS
		SELECT DISTINCT RVirus_NMDS_E.*, 
			   			RVirus_NHI.&dateOfBirth
		FROM RVirus_NHI
		LEFT JOIN RVirus_NMDS_E
		ON RVirus_NMDS_E.&primaryKey = RVirus_NHI.&primaryKey
		WHERE RVirus_NMDS_E.&primaryKey NE "";

		/*
			Set &NNMDS_numOfEntries to the total number of entries provided by the NMDS_events_file.
		*/
		SELECT COUNT(*) 
		INTO :NMDS_numOfEntries SEPARATED BY '' 
		FROM &NMDS_events_file;

		/* 
			Create a table with unique NMDS_Diag entries where &diagsType = &diagsTypeFlag.
			The choice of sorting is to by &eventId and &icdType in descending order.
		*/
		CREATE TABLE RVirus_NMDS_D AS
		SELECT DISTINCT &eventId, &icdCode, &icdType
		FROM &NMDS_diags_file
		WHERE &diagsType = &diagsTypeFlag
		%IF (&diagsTypeFlag NE "A") %THEN %DO;
			ORDER BY &eventId, &icdCode, &icdType desc;
		%END; %ELSE %DO;
			ORDER BY &eventId, &icdType desc;
		%END;

		/*
			Remove the following tables because they are not needed the rest of the module.
		*/
		DROP TABLE RVirus_NHI, RVirus_NMDS_E;
	QUIT;

	/*
		The first NMDS_Diag entry within &eventId will be the entry which contains the newest system of ICD codes.
	*/
	DATA RVirus_NMDS_D;
		SET RVirus_NMDS_D;
		%IF (&diagsTypeFlag NE "A") %THEN %DO;
			BY &eventId &icdCode;
			IF first.&icdCode THEN OUTPUT;
		%END; %ELSE %DO;
			BY &eventId;
			IF first.&eventId THEN OUTPUT;
		%END;
	RUN;

	PROC SQL NOPRINT;
		/*
			Drop entries NMDS_Diag which are not part of our ICD codes of interest.
		*/
		DELETE FROM RVirus_NMDS_D
		WHERE NOT(&icdCode IN &rotavirusCodes OR &icdCode IN &intussusceptionCodes OR &icdCode IN &bronchiolitisCodes);

		/* 
			Merge the NMDS_Diag table onto the NMDS_Base table by &eventId. Note that we only select unique NMDS_Diag entries 
			from the merged table. The type of merge is a LEFT JOIN and the WHERE part of the call ensures that 
			we will only select NMDS_Diag entries for &primaryKeys in the NMDS_Base table.
		*/
		CREATE TABLE NMDS_Complete AS
		SELECT DISTINCT NMDS_Base.*, 
						RVirus_NMDS_D.&icdCode
		FROM NMDS_Base
		LEFT JOIN RVirus_NMDS_D
		ON NMDS_Base.&eventId = RVirus_NMDS_D.&eventId
		WHERE &icdCode NE "";

		/*
			Set &NMDS_notInCohort_count to the total number of entries provided by the NMDS_Complete table.
		*/
		SELECT COUNT(*) 
		INTO :NMDS_notInCohort_count SEPARATED BY '' 
		FROM NMDS_Complete;

		/*
			Remove the following tables because they are not needed the rest of the module.
		*/
		DROP TABLE NMDS_Base, RVirus_NMDS_D;
	QUIT;

	/*
		Update &NMDS_notInCohort_count to store the number of entries dropped because they were not in the provided NHI cohort.
	*/
	%LET NMDS_notInCohort_count = %EVAL(&NMDS_numOfEntries - &NMDS_notInCohort_count);

	/*
		The choice of sorting to apply an exclusion filter for NMDS entries is by
		&primaryKey &admssnDate.
	*/
	PROC SORT data = NMDS_Complete;
		BY &primaryKey &admssnDate;
	DATA NMDS_Complete;
		SET NMDS_Complete;
		BY &primaryKey &admssnDate;
		FORMAT event $24.;
	
		/*
			Make sure that SAS "carries" forward an admission date within a person's NMDS entries.
			Create the variable repeatCount which tracks how many NMDS entries were dropped due to the
			exclusion period.
		*/
		RETAIN crrntAdmssnDate repeatCount;

		IF first.&primaryKey THEN DO;
			/* 
				If this is a person's first NMDS entry, reset seq_id and crrntAdmssnDate.
			*/
			SEQ_ID = 0;
			crrntAdmssnDate = &admssnDate;
		END; ELSE DO;
			/* 
				If this is not a person's first NMDS entry, check the difference in days between &admssnDate and crrntAdmssnDate.
			*/
			%IF (&diagsTypeFlag NE "A") %THEN %DO;
				IF (&admssnDate - crrntAdmssnDate) > &exclusionDays OR &admssnDate = crrntAdmssnDate THEN
			%END; %ELSE %DO;
				IF (&admssnDate - crrntAdmssnDate) > &exclusionDays THEN
			%END;
				/* 
					Set crrntAdmssnDate to &admssnDate if the difference is greater than &exclusionDays.
				*/
				crrntAdmssnDate = &admssnDate;
			ELSE DO;
				/* 
					Else, delete the person's NMDS entry.
				*/

				repeatCount + 1;
				DELETE;
			END;
		END;

		/*
			Set &NMDS_repeat_count to the value repeatCount.
		*/
		CALL SYMPUT('NMDS_repeat_count', repeatCount);
		
		/*
			Calculate the age of admission for the NMDS entry (in months).
		*/	
		ageOfAdmission = INTCK('MONTH', &dateOfBirth, &admssnDate, 'C');

		/*
			Create the variable event is set to a label which represents one of the ICD code groups.
		*/
		IF &icdCode IN &rotavirusCodes THEN
			event = &rotavirusLabel;
		ELSE IF &icdCode IN &intussusceptionCodes THEN
			event = &intussusceptionLabel;
		ELSE IF &icdCode IN &bronchiolitisCodes THEN
			event = &bronchiolitisLabel;

		/*
			Increment SEQ_ID. This is variable will be used in the PROC SQL styled transpose.
		*/
		SEQ_ID + 1;

		DROP crrntAdmssnDate repeatCount;
	RUN;

	/*
		The last component to this module is to transpose the data.
	*/
	PROC SQL NOPRINT;
		/*
			Set numOfHosEntries to the number of NMDS entries for a person.
		*/
		CREATE TABLE RVirus_numOfEntries AS
		SELECT &primaryKey, COUNT(SEQ_ID) AS numOfHosEntries
		FROM NMDS_Complete
		GROUP BY &primaryKey;

		/*
			Set &NMDS_maxWidth to the maximum number of NMDS entries for a person in NMDS_Complete.
		*/
		SELECT MAX(SEQ_ID)
		INTO :NMDS_maxWidth SEPARATED BY ''
		FROM NMDS_Complete;

		%DO i = 1 %TO &NMDS_maxWidth;
			/*
				Create a table which contains the "&i"th SEQ_ID in NMDS_Complete.
			*/
			CREATE TABLE NMDS_part&i AS
				SELECT &primaryKey,
					   &eventID AS &eventID._&i, 
					   &admssnDate AS &admssnDate._&i,
					   &dschrgDate AS &dschrgDate._&i,
					   event AS event_&i,
					   &icdCode AS &icdCode._&i,
					   ageOfAdmission AS ageOfAdmission_&i
				FROM NMDS_Complete
				WHERE SEQ_ID = &i;
		%END;

		/*
			"Transpose" NMDS_Complete by left joining the tables created above.
		*/
		CREATE TABLE NMDS_Transpose AS
		SELECT B.numOfHosEntries,
			   %DO i = 1 %TO &NMDS_maxWidth;
					&eventID._&i, 
					&admssnDate._&i,
					&dschrgDate._&i,
					event_&i,
					&icdCode._&i,
					ageOfAdmission_&i,
			   %END;
			   A.&primaryKey
		FROM NMDS_part1 AS A 
		LEFT JOIN RVirus_numOfEntries AS B
			ON A.&primaryKey = B.&primaryKey

		%DO i = 2 %TO &NMDS_maxWidth;
			LEFT JOIN NMDS_part&i AS A&i
				ON A.&primaryKey = A&i..&primaryKey
		%END;
		;
		
		%DO i = 1 %TO &NMDS_maxWidth;
			DROP TABLE NMDS_part&i;
		%END;

		/*
			Remove the following tables because they are not needed the rest of the module.
		*/
		DROP TABLE NMDS_Complete, RVirus_numOfEntries;
	QUIT;

	/*
		Output the macro variables created to keep track the number of deleted observations to the global environment.
	*/
	DATA _NULL_;
		CALL SYMPUTX('NMDS_repeat_count', &NMDS_repeat_count, 'G');
		CALL SYMPUTX('NMDS_notInCohort_count', &NMDS_notInCohort_count, 'G');
		CALL SYMPUTX('NMDS_numOfEntries', &NMDS_numOfEntries, 'G');
	RUN;

%MEND NMDS_Module;
