@REM Usage: deltaL_proc listfile_path outdir_path

@REM 
@REM Detect # of input arguments
@ECHO OFF
set argCount=0
for %%x in (%*) do (
   set /A argCount+=1
   set "argVec[!argCount!]=%%~x"
)


@IF NOT %argCount%==2 (@IF %argCount%==0 (GOTO args_count_gui) ELSE (GOTO args_count_wrong)) ELSE (GOTO args_count_ok)

:args_count_wrong
@ECHO Incorrect number of arguments
@ECHO Usage: deltaL_proc listfile_path outdir_path
@EXIT /b 1

:args_count_gui
call C:\Python\Miniconda3\Scripts\activate.bat C:\Python\Miniconda3
python deltaL_proc_proto.py
@EXIT /b 1

:args_count_ok
call C:\Python\Miniconda3\Scripts\activate.bat C:\Python\Miniconda3
python deltaL_proc_proto.py -l  %1 -o %2
