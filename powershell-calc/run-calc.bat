@echo off

cd %~dp0
echo( && echo(

:: calls -> loanCalc(principal, interestRate, periodsPerYear, numberOfYears)

powershell.exe -executionpolicy bypass .\calculator.ps1 1000 5 12 1

echo( && echo(
pause
exit