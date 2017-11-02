/*==================================================================================*/
/* The macro function NIR_Module() produces four SAS database called RVirus_Base_A, */
/* RVirus_Base_B, RVirus_Transpose_A, and RVirus_Transpose_B. The difference 		*/
/* between "A" and "B" is that the "A" only contain people with three or fewer 		*/
/* NIR entries and "B" only contain people with four or more NIR entries. 			*/
/* Regardless of the suffix, RVirus_Base_<suffix> contains the following columns	*/
/* with the default arguments:														*/
/*	- MASTER_HCU_ID																	*/
/*	- numOfImmEntries																*/
/*	- VACCINATION_DATE																*/
/*	- AGE_IN_MONTHS																	*/
/*	- EVENT_STATUS_DESCRIPTION														*/
/*	- EVENT_SUB_STATUS_DESCRIPTION													*/
/*	- expectedVaccineNum															*/
/*	- ANTIGEN																		*/
/*	- VACCINE																		*/
/*	- SEQ_ID																		*/
/*																					*/
/* The RVirus_Transpose_<suffix> contains all of the columns found in 				*/
/* RVirus_Base_<suffix> except for the SEQ_ID column.								*/
/*																					*/
/* The macro function NIR_Module() also produces the following macro variables:		*/
/* - &NIR_numOfEntries: The total number of distinct NIR entries.					*/
/* - &NIR_notInCohort_count: The number of entries which were dropped because they  */
/*		were not in the NHI cohort of interest.										*/
/* - &NIR_ngtvAIM_count: The number of entries dropped due to a negative value for	*/
/*		their age in months at the date of vaccination.								*/
/* - &NIR_cnctntd_count: The number of entries dropped due to concatenating the		*/
/*		eventDescription column. 													*/
/* - &NIR_dblConflict_count: The number of entries dropped due to conflicting 		*/
/*		eventStatus at a given immunisation date.									*/
/* - &NIR_invalid_count: The number of entries dropped due to the first NIR entry 	*/
/*		recorded before a person is 38 days old.									*/
/* - &NIR_outOfScope_count: The number of entries dropped due to the immunisation 	*/
/*		date not being within the expected date ranges.								*/
/* - &NIR_cnsctve_count: The number of entries dropped due to person having			*/ 
/*		consecutive NIR entries which were a day apart for a scheduled vaccination.	*/
/* - &NIR_4Plus_Entries_count: The number of entries in RVirus_Base_B.				*/
/*																					*/
/* The macro function NIR_Module() has the following arguments:						*/
/*	- NHI_File: The name of the NHI SAS database.									*/
/*		Default Value = Bp9P2J.Mis3090_cohort.										*/
/*	- NIR_File: The name of the NIR SAS database.									*/
/*		Default Value = Bp9P2J.Nir_rotavirus.										*/
/*																					*/
/*	- primaryKey: The name of the column which contains a person's unique			*/ 
/*		identifier in NHI_File and NIR_File. Default Value = MASTER_HCU_ID.			*/
/*	- dateOfBirth: The name of the column which contains a person's date of	birth	*/
/*		entry in the NHI_File. Default Value = DOB.									*/
/*																					*/
/*	- dateOfImmunisation: The name of the column which contains an entry's			*/
/*		immunisation date in the NIR_File.											*/
/*		Default Value = VACCINATION_DATE.	  										*/
/*	- eventStatus: The name of the column which contains an entry's immunisation 	*/
/*		event description in the NIR_File.											*/
/*		Default Value = EVENT_STATUS_DESCRIPTION.									*/
/*	- eventDescription: The name of the column which contains any additional		*/
/*		information about an entry's immunisation event description in the 			*/
/*		NIR_File. Default Value = EVENT_SUB_STATUS_DESCRIPTION.						*/
/*	- vaccine: The name of the column which contains the name of the vaccine.		*/
/*		Default Value = VACCINE.													*/
/*	- antigen: The name of the column which contains the name of the antigen used 	*/
/*		in the vaccine. Default Value = ANTIGEN.									*/
/*																					*/
/*	- ageInMonths: The name of the derived column which calculates a person's age 	*/
/*		(in months) at the immunisation date. Default Value = AGE_IN_MONTHS.		*/
/*																					*/
/*	- filterCondition: A SAS condition that determines which entries are chosen		*/
/*		from the NIR_File (enclosed in brackets and do not use the quotation 		*/
/*		character, ", in the conditions).											*/
/*		Default value = (ANTIGEN = 'Rotavirus' & VACCINE = 'Rotavirus').			*/
/*																					*/
/*==================================================================================*/

%MACRO NIR_Module(NHI_File = Bp9P2J.Mis3090_cohort, NIR_File = Bp9P2J.Nir_rotavirus,
	primaryKey = MASTER_HCU_ID, dateOfBirth = DOB,
	dateOfImmunisation = VACCINATION_DATE, eventStatus = EVENT_STATUS_DESCRIPTION, eventDescription = EVENT_SUB_STATUS_DESCRIPTION, vaccine = VACCINE, antigen = ANTIGEN, 
	ageInMonths = AGE_IN_MONTHS, 
	filterCondition = (ANTIGEN = 'Rotavirus' AND VACCINE = 'Rotavirus')
	);

	/* 
		Remove the brackets from the &selectVars and &filterCondition arguments.
	*/
	%LET filterCondition = %SYSFUNC(COMPRESS(%QUOTE(&filterCondition), "()"));

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
			Create a table with unique NIR entries which meet the &filterCondition.
		*/
		CREATE TABLE RVirus_NIR AS
		SELECT DISTINCT *
		FROM &NIR_File
		WHERE &filterCondition
		ORDER BY &primaryKey, &dateOfImmunisation;

		/* 
			Merge the NIR table onto the NHI table by &primaryKey. Note that we only select unique NIR entries 
			from the merged table. The type of merge is a LEFT JOIN and the WHERE part of the call ensures that 
			we will only select NIR entries for &primaryKeys in the NHI table.
		*/
		CREATE TABLE RVirus_Base AS
		SELECT DISTINCT RVirus_NIR.&primaryKey, 
						RVirus_NHI.&dateOfBirth,
						RVirus_NIR.&dateOfImmunisation,
						RVirus_NIR.&eventStatus,
						RVirus_NIR.&eventDescription,
						RVirus_NIR.&vaccine,
						RVirus_NIR.&antigen
		FROM RVirus_NHI
		LEFT JOIN RVirus_NIR
		ON RVirus_NHI.&primaryKey = RVirus_NIR.&primaryKey
		WHERE RVirus_NIR.&primaryKey NE "";

		/*
			Create four new columns in the resulting table and...
		*/
		ALTER TABLE RVirus_Base
      	ADD &ageInMonths NUM FORMAT = 3.0,
			DevFrm_6Weeks NUM FORMAT = 6.0,
			DevFrm_3Months NUM FORMAT = 6.0,
			DevFrm_5Months NUM FORMAT = 6.0;

		UPDATE RVirus_Base
		/* 
			Set &ageInMonths to "&dateOfImmunisation - &dateOfBirth" in months. 
			Set DevFrm_<Unit> to "&dateOfImmunisation - (&dateOfBirth + <Unit>)" in days
			where <Unit> can be 6 Weeks, 3 Months, or 5 Months.
		*/
      	SET	&ageInMonths = INTCK('MONTH', &dateOfBirth, &dateOfImmunisation, 'C'),
			DevFrm_6Weeks = &dateOfImmunisation - INTNX('WEEKS', &dateOfBirth, 6, 'SAME'),
			DevFrm_3Months = &dateOfImmunisation - INTNX('MONTHS', &dateOfBirth, 3, 'SAME'),
			DevFrm_5Months = &dateOfImmunisation - INTNX('MONTHS', &dateOfBirth, 5, 'SAME');
		
		/*
			Set &NIR_numOfEntries to the total number of entries provided by the NIR database.
		*/
		SELECT COUNT(*) 
		INTO :NIR_numOfEntries SEPARATED BY '' 
		FROM &NIR_File;

		/*
			Set &NIR_nnUnique_count to the total number of entries in the RVirus_Base table.
		*/
		SELECT COUNT(*) 
		INTO :NIR_notInCohort_count SEPARATED BY '' 
		FROM RVirus_Base;

		/*
			Set &NIR_ngtvAIM_count to the number of entries dropped because their &ageInMonths was negative.
		*/
		SELECT COUNT(*) 
		INTO :NIR_ngtvAIM_count SEPARATED BY '' 
		FROM RVirus_Base
		WHERE &ageInMonths < 0;
		
		/*
			It has been recommended to drop NIR entries where &ageInMonths is negative by the client.
		*/
		DELETE FROM RVirus_Base
		WHERE &ageInMonths < 0;

		/*
			Remove the following tables because they are not needed the rest of the module.
		*/
		DROP TABLE RVirus_NIR, RVirus_NHI;
	QUIT;

	/*
		Update &NIR_notInCohort_count to store the number of entries dropped because they were not in the provided NHI cohort.
	*/
	%LET NIR_notInCohort_count = %EVAL(&NIR_numOfEntries - &NIR_notInCohort_count);

	/*
		The choice of sorting to deal with immunisation dates with duplicate NIR entries is by
		&primaryKey &dateOfImmunisation &eventStatus.
	*/
	PROC SORT DATA = RVirus_Base;
		BY &primaryKey &dateOfImmunisation &eventStatus &vaccine &antigen;

	/*
		Set &NIR_cnctntd_count to 0.
	*/
	%LET NIR_cnctntd_count = 0;

	DATA RVirus_Base;
		/*
			Create the column tempDescription to hold the concatenated "&eventDescription"s.
		*/
		LENGTH tempDescription $160.;

		/*
			For each immunisation date within a person's NIR entries:
		*/
		DO UNTIL (last.&eventStatus);
			SET RVirus_Base;
			BY &primaryKey &dateOfImmunisation &eventStatus &vaccine &antigen;

			/*
				Concatenate the "&eventDescription"s together to reduce the number of effective NIR entries.
			*/
			tempDescription = CATX(', ', tempDescription, &eventDescription);

			/*
				Create a variable called cntctCount which tracks how many times a concatenation happened in the DATA step.
			*/
			RETAIN cntctCount;
			IF ^first.&eventStatus THEN cntctCount + 1;

			/*
				Initialise the "which vaccination" encodings.
			*/
			vaccineOne = 0; vaccineTwo = 0; vaccineThree = 0;

			/*
				Label a NIR entry as the first vaccination if it is between 38 days to 12 weeks of age.
			*/
			IF -4 =< DevFrm_6Weeks =< 42 THEN vaccineOne = 1;
			
			/*
				Label a NIR entry as the second vaccination if it is at 3 months +/- 6 weeks.
			*/
			IF -42 =< DevFrm_3Months =< 42 THEN vaccineTwo = 1;

			/*
				Label a NIR entry as the third vaccination if it is third vaccination at 5 months +/- 6 weeks.
			*/
			IF -42 =< DevFrm_5Months =< 42 THEN vaccineThree = 1;

			/*
				Ensure that within a NIR entry that only one of vaccineOne, vaccineTwo or vaccineThree is equal to one.
				Note that the code will always favour the earliest out of the two possible "which vaccination" labels.
			*/
			IF (vaccineOne + vaccineTwo + vaccineThree) ^= 1 THEN DO;
				IF vaccineOne = 1 AND vaccineTwo = 1 AND vaccineThree = 0 THEN DO;
					IF ABS(DevFrm_6Weeks) => ABS(DevFrm_3Months) 
						THEN vaccineOne = 0;
						ELSE vaccineTwo = 0;
				END;
				IF vaccineOne = 0 AND vaccineTwo = 1 AND vaccineThree = 1 THEN DO;
					IF ABS(DevFrm_3Months) => ABS(DevFrm_5Months) 
						THEN vaccineTwo = 0;
						ELSE vaccineThree = 0;
				END;

				IF vaccineOne = 1 AND vaccineTwo = 0 AND vaccineThree = 1 THEN DO;
					IF ABS(DevFrm_6Weeks) => ABS(DevFrm_5Months) 
						THEN vaccineOne = 0;
						ELSE vaccineThree = 0;
				END;
			END;
		END;

		/*
			Set &NIR_cnctntd_count to the value of cntctCount.
		*/
		CALL SYMPUT('NIR_cnctntd_count', cntctCount);

		DROP &eventDescription cntctCount;
		RENAME tempDescription = &eventDescription;

	/*
		Set &NIR_dblConflict_count, &NIR_invalid_count and &NIR_cnsctveCount to 0.
	*/
	%LET NIR_dblConflict_count = 0;
	%LET NIR_invalid_count = 0;
	%LET NIR_cnsctveCount = 0;
	
	DATA RVirus_Base;		
		RETAIN &primaryKey &dateOfBirth &dateOfImmunisation &ageInMonths
			   &eventStatus &eventDescription
			   expectedVaccineNum
			   &vaccine &antigen;
		SET RVirus_Base;
		BY &primaryKey &dateOfImmunisation &eventStatus &vaccine &antigen;

		/*
			Create the variables dblConflictCount, outOfScopeCount, cnsctveCount, and invalidCount. Respectively they
			track how many NIR entries on the same date which have a conflicting &eventStatus, how many NIR entries 
			weren't recorded within the allowable ranges for a Rotavirus vaccination, how many NIR entries for a person
			were removed because the following NIR entry was date consecutive AND had the same expectedVaccine label, and
			how many entries were removed if a person's NIR entries were invalid because an immunisation date was before 
			they were 39 days old. 
		*/
		RETAIN dblConflictCount invalidCount outOfScopeCount cnsctveCount 
			   prevDate prevLabel prevEvent prevVaccine prevAntigen invalid;
		LENGTH prevEvent $160. prevVaccine $160. prevAntigen $160.;

		/*
			Keep the NIR entry which has a "Completed" &eventStatus when there are conflicting "&eventStatus"s
			at a given immunisation date. 
		*/
		IF first.&dateOfImmunisation ^= last.&dateOfImmunisation THEN DO;
			IF &eventStatus ^= 'Completed' THEN DO;
				dblConflictCount + 1;
				DELETE;
			END;
		END;

		/*
			Reset the invalid, seq_id, prevDate, and prevLabel variables at a person's first vaccination entry.
		*/
		IF first.&primaryKey THEN DO;
			SEQ_ID = 0;
			invalid = 0;
			prevDate = 0;
			prevLabel = 0;
			prevEvent = ' ';
			prevVaccine = ' ';
			prevAntigen = ' ';
		END;

		/*
			A person's NIR entries are invalid if the first NIR entry is before 38 days of age.
		*/
		IF DevFrm_6Weeks =< -5 THEN invalid = 1;
		IF invalid = 1 THEN DO;
			invalidCount + 1;
			DELETE;
		END;

		/*
			If the sum of vaccineOne, vaccineTwo, and vaccineThree is 0, this indicates that 
			the immunisation was done outside of the allowable dates for a Rotavirus immunisation.
		*/
		IF (vaccineOne + vaccineTwo + vaccineThree) = 0 THEN DO;
			outOfScopeCount + 1;
			DELETE;
		END;

		/*
			Create a variable called expectedVaccineNum which denotes whether the NIR entry corresponds to
			the first, second, or third vaccination given the immunisation date.
		*/
		IF vaccineOne = 1 THEN expectedVaccineNum = 1;
		IF vaccineTwo = 1 THEN expectedVaccineNum = 2;
		IF vaccineThree = 1 THEN expectedVaccineNum = 3;

		/*
			Check whether the NIR entry is a near carbon copy of the previous entry, if so, delete the NIR entry. 
		*/
		IF (expectedVaccineNum = prevLabel) AND 
			(&dateofImmunisation - prevDate) = 1 AND 
			(&eventStatus = prevEvent) AND
			(&vaccine = prevVaccine) AND
			(&antigen = prevAntigen) THEN DO;
				cnsctveCount + 1;
				DELETE;
		END;

		/*
			Increment SEQ_ID. This is variable will be used in the PROC SQL styled tranpose.
		*/
		SEQ_ID + 1;

		/*
			Set prevDate to &dateOfImmunisation, prevLabel to expectedVaccineNum, and prevEvent to &eventStatus.
		*/
		prevDate = &dateOfImmunisation;
		prevLabel = expectedVaccineNum;
		prevEvent = &eventStatus;
		prevVaccine = &vaccine;
		prevAntigen = &antigen;

		/*
			Set &NIR_dblConflict_count to the value of dblConflictCount, &NIR_invalid_count to the value of invalidCount,
			&NIR_outOfScope_count to the value of outOfScopeCount, and &NIR_cnvsctve_count to the value of cnsctveCount.
		*/
		CALL SYMPUT('NIR_dblConflict_count', dblConflictCount);
		CALL SYMPUT('NIR_invalid_count', invalidCount);
		CALL SYMPUT('NIR_outOfScope_count', outOfScopeCount);
		CALL SYMPUT('NIR_cnsctve_count', cnsctveCount);

		DROP dblConflictCount 
			 invalid invalidCount 
			 outOfScopeCount 
			 cnsctveCount
			 DevFrm_6Weeks DevFrm_3Months DevFrm_5Months
			 vaccineOne vaccineTwo vaccineThree
			 prevDate prevLabel prevEvent prevVaccine prevAntigen;
	RUN;

	/*
		The last component to this module is to transpose the data.
	*/
	PROC SQL NOPRINT;
		/*
			Set numOfImmEntries to the number of NIR entries for a person.
		*/
		CREATE TABLE RVirus_numOfEntries AS
		SELECT &primaryKey, COUNT(SEQ_ID) AS numOfImmEntries
		FROM RVirus_Base
		GROUP BY &primaryKey;

		/* 
			Split RVirus_Base into RVirus_Base_A and RVirus_Base_B.
			Base_A contains people with three or less NIR entries...
		*/
		CREATE TABLE RVirus_Base_A AS
		SELECT A.*, B.numOfImmEntries
		FROM RVirus_Base AS A 
		LEFT JOIN RVirus_numOfEntries AS B
			ON A.&primaryKey = B.&primaryKey
		WHERE B.numOfImmEntries <= 3;

		/* 
			... while Base_B contains people with four or more NIR entries.
		*/
		CREATE TABLE RVirus_Base_B AS
		SELECT A.*, B.numOfImmEntries
		FROM RVirus_Base AS A 
		LEFT JOIN RVirus_numOfEntries AS B
			ON A.&primaryKey = B.&primaryKey
		WHERE B.numOfImmEntries > 3;

		/*
			Set &NIR_4PlusEntries_Count to the number of entries in Base_B.
		*/
		SELECT COUNT(*) 
		INTO :NIR_4PlusEntries_count SEPARATED BY '' 
		FROM RVirus_Base_B;

		/*
			With a macro %DO loop:
		*/ 
		%DO letterIndex = %SYSFUNC(RANK(A)) %TO %SYSFUNC(RANK(B));
			/*
				Set &letter to BYTE(&letterIndex).
			*/
			%LET letter = %SYSFUNC(BYTE(&letterIndex));
			
			/*
				Set &NIR_maxWidth to the maximum number of NIR entries for a person in RVirus_Base_&letter.
			*/
			SELECT MAX(SEQ_ID)
			INTO :NIR_maxWidth SEPARATED BY '' 
			FROM RVirus_Base_&letter;
			
			%DO i = 1 %TO &NIR_maxWidth;
				/*
					Create a table which contains the "&i"th SEQ_ID in RVirus_Base_&letter.
				*/
				CREATE TABLE RVirus_part&i AS
				SELECT &dateOfImmunisation AS &dateOfImmunisation._&i,
					   &ageInMonths AS &ageInMonths._&i,
			   		   &eventStatus AS &eventStatus._&i,
					   &eventDescription AS &eventDescription._&i,
			   		   expectedVaccineNum AS expectedVaccineNum_&i,
			   		   &vaccine AS &vaccine._&i,
					   &antigen AS &antigen._&i,
					   &primaryKey,
					   numOfImmEntries,
					   &dateOfBirth
				FROM RVirus_Base_&letter
				WHERE SEQ_ID = &i;
			%END;

			/*
				"Transpose" RVirus_Base_&letter by left joining the tables created above.
			*/
			CREATE TABLE RVirus_Transpose_&letter AS
			SELECT A1.&primaryKey,
				   A1.numOfImmEntries, 
				   %DO i = 1 %TO &NIR_maxWidth;
				   	   &dateOfImmunisation._&i,
					   &ageInMonths._&i,
			   		   &eventStatus._&i,
					   &eventDescription._&i,
			   		   expectedVaccineNum_&i,
			   		   &vaccine._&i,
					   &antigen._&i,
				   %END;
				   A1.&dateOfBirth
			FROM RVirus_part1 AS A1

			%DO i = 2 %TO &NIR_maxWidth;
				LEFT JOIN RVirus_part&i AS A&i
					ON A1.&primaryKey = A&i..&primaryKey
			%END;
			;

			%DO i = 1 %TO &NIR_maxWidth;
				DROP TABLE RVirus_part&i;
			%END;
			
			/*
				Drop &dateOfBirth from RVirus_Base_&letter and RVirus_Tranpose_&letter because that will retained by the NHI module.
			*/
			ALTER TABLE RVirus_Base_&letter DROP &dateOfBirth;
			ALTER TABLE RVirus_Transpose_&letter DROP &dateOfBirth;
		%END;

		/*
			Remove the following tables because they are not needed the rest of the module.
		*/
		DROP TABLE RVirus_numOfEntries, RVirus_Base;
	QUIT;

	/*
		Output the macro variables created to keep track the number of deleted observations to the global environment.
	*/
	DATA _NULL_;
		CALL SYMPUTX('NIR_numOfEntries', &NIR_numOfEntries, 'G');
		CALL SYMPUTX('NIR_notInCohort_count', &NIR_notInCohort_count, 'G');
		CALL SYMPUTX('NIR_ngtvAIM_count', &NIR_ngtvAIM_count, 'G');
		CALL SYMPUTX('NIR_cnctntd_count', &NIR_cnctntd_count, 'G');
		CALL SYMPUTX('NIR_dblConflict_count', &NIR_dblConflict_count, 'G');
		CALL SYMPUTX('NIR_invalid_count', &NIR_invalid_count, 'G');
		CALL SYMPUTX('NIR_outOfScope_count', &NIR_outOfScope_count, 'G');
		CALL SYMPUTX('NIR_4PlusEntries_count', &NIR_4PlusEntries_count, 'G');
		CALL SYMPUTX('NIR_cnsctve_count', &NIR_cnsctve_count, 'G');
	RUN;

%MEND NIR_Module;
