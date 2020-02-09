@REM Usage: singleL_proc listfile_path outdir_path lowfreq

@REM 
@REM Detect # of input arguments
@ECHO OFF
set argCount=0
for %%x in (%*) do (
   set /A argCount+=1
   set "argVec[!argCount!]=%%~x"
)


@IF NOT %argCount%==3 (@IF %argCount%==0 (GOTO args_count_gui) ELSE (GOTO args_count_wrong)) ELSE (GOTO args_count_ok)

:args_count_wrong
@ECHO Incorrect number of arguments
@ECHO Usage: singleL_proc listfile_path outdir_path lowfreq
@EXIT /b 1

:args_count_gui
call C:\Python\Miniconda3\Scripts\activate.bat C:\Python\Miniconda3
python singleL_proc_proto.py
@EXIT /b 1

:args_count_ok
call C:\Python\Miniconda3\Scripts\activate.bat C:\Python\Miniconda3
python singleL_proc_proto.py -l  %1 -o %2 -f %3
