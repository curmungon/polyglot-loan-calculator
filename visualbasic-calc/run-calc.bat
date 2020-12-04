@echo off

cd %~dp0
echo( && echo(

:: calls -> loanCalc(principal, interestRate, periodsPerYear, numberOfYears)

cscript.exe .\calculator.vbs 1000 5 12 1

echo( && echo(
pause
exit