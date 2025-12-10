Shift + F10
```
diskpart
```
```
list disk
```
```
select disk X(ZB. 1 - muss ziellaufwerk sein)
```
```
clean
```
```
create partition primary
```
```
format fs=ntfs quick
```
```
active
```
```
exit
```
```
diskpart
```
```
list volume
```
```
exit
```
```
xcopy D(media creation toll usb stick volume buchstabe):\* E(ziel lauferk buchstabe:\ /E /H /F
```
