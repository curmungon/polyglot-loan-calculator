@echo off

cd %~dp0
echo( && echo(

:: calls -> loanCalc(principal, interestRate, periodsPerYear, numberOfYears)

node .\dist\calculator.js 1000 5 12 1

echo( && echo(
pause
exit