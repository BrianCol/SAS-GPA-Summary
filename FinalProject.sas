/*Import FormA csv file into SAS as work.FormA  */
proc import datafile = "/folders/myfolders/HW124/FinalProject/FormA.csv" dbms=csv
	out = work.FormA replace;
run;

/*Import FormB csv file into SAS as work.FormB  */
proc import datafile = "/folders/myfolders/HW124/FinalProject/FormB.csv" dbms=csv
	out = work.FormB replace;
run;

/*Import Domains_FormB csv file into SAS as work.Domains_FormB  */
proc import datafile = "/folders/myfolders/HW124/FinalProject/Domains FormB.csv" dbms=csv
	out = work.Domains_FormB replace;
run;

/*Import Domains_FormA csv file into SAS as work.Domains_FormA  */
proc import datafile = "/folders/myfolders/HW124/FinalProject/Domains FormA.csv" dbms=csv
	out = work.Domains_FormA replace;
run;
/*Set macro variable to create Form A or Form B  */
%let file_form = A;

/*create two tables (one for form A and one for form B) that display whether students got each question correct   */
/*Part 1  */
data correct&file_form;
	set Form&file_form;
	
	array Form&file_form(150) $ Q1-Q150;
	array answer(150) $ Answer1-Answer150;
	
	retain Answer1-Answer150;
	
	Form = "&file_form";
	
	if Student = "BBBBKEY" or Student = "AAAAKEY" then do i = 1 to 150;
		answer(i) = Form&file_form(i);
	end;

	else do Question = 1 to 150;
		if answer(Question) = Form&file_form(Question) then Scores = 1;
		else Scores = 0;
		keep Student Scores Question Form;
		output;
	end;
run;

/* proc print data = correct&file_form (OBS = 10) noobs; */
/* run; */


/*Part 2  */
/*Merge the two tables (FormA and Domains_FormA)  */
proc sql; 
	create table work.Form_merged_&file_form as
	select Question, Scores, Student, Form, DomainNum
	from  correct&file_form inner join Domains_Form&file_form
	on Question = QuestionNum;
run;

/*Print merged employees and employees_sales table  */
/* title "FormA and Domains FormA Merged";  */
/* proc print data = work.Form_merged_&file_form noobs; */
/* run; */


/*Part 3  */
/*Combine the two tables (Form_merged_A and Form_merged_B) into one table (Form_AB) */
data Form_AB;
	set Form_merged_A Form_merged_B;
	output Form_AB;
run;

/*Part 4  */
/*Calculate the totalscore and percent for each student.Also calculate the student's score and percentage foreach of the five domain categories.  */
proc means data = Form_AB mean sum nonobs noprint;
	var Scores;
	class Student DomainNum;
	id Question Form;
	output out = means_Form_AB mean = percent sum = Student_Scores;
run;

/*Delete missing values, change Student to numeric, and keep variables  */
data means_Form_AB;
	set means_Form_AB;
	Student = input(Student, 8.);
	if Student <= .Z then delete;
	keep percent Student_Scores Student Form DomainNum
run; 

/*Part 5  */
/*Sort the table created in Step 4 (means_Form_AB) by Student  */
proc sort data = means_Form_AB out = sorted_Form_AB;
	by Student;
run;

/* proc print data= sorted_Form_AB; */
/* run; */

/*Part 6  */
/*Using the table (wide_sorted), create another table where each row contains all of the student scores/percentages (converting the table to “wide” format).  */
data wide_sorted;
	set sorted_Form_AB;
	array sorted_array(*) TotalPer TotalScore D1Per D1Score D2Per D2Score D3Per D3Score D4Per D4Score D5Per D5Score;
	retain TotalPer TotalScore D1Per D1Score D2Per D2Score D3Per D3Score D4Per D4Score D5Per D5Score;
	
	by Student;
	if first.Student then i = 0; 
	i + 1;
	sorted_array(i) = percent;
	i + 1;
	sorted_array(i) = Student_Scores;
	if last.Student then output;
	drop i;
run;

/*Part 7  */
/*Create side-by-side boxplots of the five domains using student percentages as the response  */
/* proc sgplot data=sorted_Form_AB; */
/* 	vbox percent/category=DomainNum; */
/* 	xaxis label = "Domain"; */
/* 	yaxis label = "Percent"; */
/* run; */

/*Part 8  */
/*Calculate the percentage correct for each question  */
proc means data = Form_AB mean nonobs noprint;
	var Scores;
	class Question Form;
	id Question Form;
	output out = means_Question mean = Scores;
run;

/*Delete missing data  */
data clean_Question;
	set means_Question;
	if Form = ' ' then delete;
	if Question <= .Z then delete;
run; 

/*Sorted data by Form  */
proc sort data = clean_Question out = sorted_Question;
	by Form;
run;

/* proc print data= sorted_Question; */
/* run; */

/*Part 9  */
/*Output as pdf file */
/*Create a final report with two sections as described below  */
ods pdf file = "/folders/myfolders/HW124/FinalProject/FinalProject.pdf";
options orientation=landscape;
options nodate nonumber;

/*Reorder columns, set format as percentae, and label columns*/
data reorder_wide_sorted;
	retain Student Form TotalScore TotalPer D1Score D2Score D3Score D4Score D5Score D1Per D2Per D3Per D4Per D5Per;
	set wide_sorted;
	format TotalPer D1Per D1Per D2Per D3Per D4Per D5Per percent10.1;
	label TotalScore = "Overall Score" TotalPer = "Overall Percentage" D1Score = "Domain 1 Score" D1Per = "Domain 1 Percentage" D2Score = "Domain 2 Score" D2Per = "Domain 2 Percentage" D3Score = "Domain 3 Score" D3Per = "Domain 3 Percentage" D4Score = "Domain 4 Score" D4Per = "Domain 4 Percentage" D5Score = "Domain 5 Score" D5Per = "Domain 5 Percentage";
run;

/*Print a table sorted by Student ID  */
title "Section A: Student Scores Sorted by Student ID";
proc print data = reorder_wide_sorted (drop = percent DomainNum Student_Scores ) noobs label;
run;

/*Reorder columns, set format percentage, and label columns*/
data order_wide_sorted;
	retain Student Form TotalPer TotalScore D1Per D2Per D3Per D4Per D5Per D1Score D2Score D3Score D4Score D5Score;
	set wide_sorted;
	format TotalPer D1Per D1Per D2Per D3Per D4Per D5Per percent10.1;
	label TotalScore = "Overall Score" TotalPer = "Overall Percentage" D1Score = "Domain 1 Score" D1Per = "Domain 1 Percentage" D2Score = "Domain 2 Score" D2Per = "Domain 2 Percentage" D3Score = "Domain 3 Score" D3Per = "Domain 3 Percentage" D4Score = "Domain 4 Score" D4Per = "Domain 4 Percentage" D5Score = "Domain 5 Score" D5Per = "Domain 5 Percentage";
run;

/*Sort data by Overall Percentage (TotalPer)  */
proc sort data = order_wide_sorted out = percent_wide_sorted;
by descending Totalper;
run;

/*Print a table (percent_wide_sorted) sorted by overall percentage  */
title "Section A: Student Scores Sorted Highest to Lowest Overall Score";
proc print data = percent_wide_sorted (drop = percent DomainNum Student_Scores ) noobs label;
run;

/*Create side-by-side boxplots of the five domains using student percentages as the response  */
title "Section A: Student Scores Boxplots of Student Percentages for the Five Domains";
proc sgplot data=sorted_Form_AB;
	vbox percent/category=DomainNum;
	xaxis label = "Domain";
	yaxis label = "Percent";
run;

/*Reorder columns, set format percentage, and label columns */
data reorder_clean_Question;
	retain Form Question Scores;
	set clean_Question;
	format Scores percent10.1;
	label Question = "Question Number" Scores = "Question Percentage";
run; 

/*Sort reorder_clean_Question by Form  */
proc sort data = reorder_clean_Question out = sorted_clean_Question;
by Form;
run;

/*Print a table (sorted_clean_Question ) sorted by exam form then by question number   */
title "Section B: Question Analysis Sorted by Exam Form and Question Number";
proc print data = sorted_clean_Question (drop= _type_ _freq_) noobs label;
run;


/*reorder columns, set percent formats, and label columns*/
data order_clean_Question;
	retain Scores Form Question;
	set clean_Question;
	format Scores percent10.1;
	label Question = "Question Number" Scores = "Question Percentage";
run;

/*Sort order_clean_Question by Scores and then Form  */
proc sort data = order_clean_Question out = sorted_easy_Question;
by descending Scores Form;
run;

/*Print a table (sorted_easy_Question) sorted by question percentage (easiest to hardest)    */
title "Section B: Question Analysis Sorted by Question Percentage";
proc print data = sorted_easy_Question (drop = _type_ _freq_) noobs label;
run;


/*End of pdf file*/
ods pdf close;


	
	
	
