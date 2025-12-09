@echo off
setlocal enabledelayedexpansion

set /p accept_eula="EULA? (ja/nein): "
set /p full_name="Name: "
set /p organization="Organisation (nein = leer): "
set /p product_key="Produktkey (nein = leer): "
set /p connect_to_microsoft="Verbindung zu Microsoft herstellen? (ja/nein): "
set /p send_info="↳Informationen senden? (ja/nein): "
set /p feedback="↳Feedback teilnehmen? (ja/nein): "
set /p enable_optional="↳optionale Netzwerkverbindungen aktivieren? (ja/nein): "
set /p language="Sprache (de-DE/en-US): "
set /p region="Region (DE/US): "
set /p layout="Tastaturlayout (de-DE/en-US): "

set xml_output="install.xml"
(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo <unattended>
echo     <UserData>
echo         <AcceptEula>%accept_eula%</AcceptEula>
echo         <FullName>%full_name%</FullName>
echo         <Organization>%organization%</Organization>
echo         <ProductKey>%product_key%</ProductKey>
echo     </UserData>
echo     <PrivacySettings>
echo         <ConnectToMicrosoft>%connect_to_microsoft%</ConnectToMicrosoft>
echo         <SendInfo>%send_info%</SendInfo>
echo         <Feedback>%feedback%</Feedback>
echo     </PrivacySettings>
echo     <Networking>
echo         <NetworkConnection>
echo             <EnableOptional>%enable_optional%</EnableOptional>
echo         </NetworkConnection>
echo     </Networking>
echo     <Locale>
echo         <Language>%language%</Language>
echo         <Region>%region%</Region>
echo     </Locale>
echo     <Keyboard>
echo         <Layout>%layout%</Layout>
echo     </Keyboard>
echo </unattended>
) > %xml_output%

start /wait setup.exe /unattended /xml:%xml_output%
