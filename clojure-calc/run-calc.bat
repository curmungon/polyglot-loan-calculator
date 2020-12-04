@echo off

cd %~dp0
echo( && echo(

:: calls -> loanCalc(principal, interestRate, periodsPerYear, numberOfYears)

java -jar .\calculator\target\uberjar\calculator-0.1.0-SNAPSHOT-standalone.jar 1000 5 12 1

echo( && echo(
pause
exit