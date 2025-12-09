@echo off
setlocal enabledelayedexpansion

set /p accept_eula="Akzeptieren Sie die EULA? (ja/nein): "
set /p full_name="Geben Sie Ihren vollständigen Namen ein: "
set /p organization="Geben Sie die Organisation ein (lassen Sie leer, wenn nicht zutreffend): "
set /p product_key="Geben Sie den Produktkey ein (lassen Sie leer, wenn nicht zutreffend): "
set /p connect_to_microsoft="Möchten Sie eine Verbindung zu Microsoft herstellen? (ja/nein): "
set /p send_info="Möchten Sie Informationen senden? (ja/nein): "
set /p feedback="Möchten Sie an Feedback teilnehmen? (ja/nein): "
set /p enable_optional="Möchten Sie optionale Netzwerkverbindungen aktivieren? (ja/nein): "
set /p language="Wählen Sie eine Sprache (de-DE/en-US): "
set /p region="Geben Sie die Region ein (z.B. DE für Deutschland, US für USA): "
set /p layout="Geben Sie das Tastaturlayout ein (z.B. de-DE für Deutsch, en-US für Englisch): "

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
