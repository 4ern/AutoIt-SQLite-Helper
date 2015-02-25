#include-once
#include <File.au3>
#include <SQLite.au3>
#include <SQLite.dll.au3>
#include <Array.au3>

;----------------------------------------------------------------------------------------------/
; Regestrierung SQL Funktions
;----------------------------------------------------------------------------------------------/
	Global Const $sql_init     = __mSQlite_Initialisieren
	Global Const $sql_get      = __mSQlite_getQuerry
	Global Const $sql_set      = __mSQlite_setQuerry
	Global Const $sql_info     = __mSqlite_Information
	Global Const $sql_flag     = __mSqlite_getSetFlag
	Global Const $sql_defaults = __mSqlite_defaults
	Global Const $sql_count    = __mSqlite_count

;----------------------------------------------------------------------------------------------/
; Beschreibung: = Initialisiere Constructor
;
; Update        = 20.02.2015		
; von           = 4ern.de
;----------------------------------------------------------------------------------------------/
func __mSQlite_Initialisieren($param1 = 0, $param2 = False)
	__m_SQLite_Constructor('create',$param1,$param2)
endfunc ;<==/newFunc

;----------------------------------------------------------------------------------------------/
; Beschreibung: = Stellt / Schließt / übergibt die Verbindungn zur Datenbank
;
; Info 			= Siehe Dokumentation
;				  https://github.com/4ern/AutoIt-SQLite-Helper/edit/master/README.md
;
; Update        = 30.10.2014
; von           = 4ern.de
;----------------------------------------------------------------------------------------------/
func __m_SQLite_Constructor($action = '',$paramDatabase = 1, $pfDll = False)

	Local Static $Start     = False
	Local Static $dbStartup = False 
	Local Static $pf_sqLiteDll 
	Local Static $pf_database
	Local Static $oConnection

	Switch $action
		Case 'pf_sqLiteDll'
			return $pf_sqLiteDll
		Case 'pf_database'
			return $pf_database
	EndSwitch
	
	;----------------------------------------------------------------------------------------------/
	; Falls keine Datenbank übergeben wurde dan versuche eine im Scriptdir zu finden.
	;----------------------------------------------------------------------------------------------/
		if $pf_database = '' then
			Switch $paramDatabase

				;Wenn Datebase Pfad initialisiert wurde
				Case StringInStr($paramDatabase, '.s3db') <> 0
					$pf_database = $paramDatabase

				;Wenn nichts mitgegeben wurde, wird versucht im ScriptDir nach DB zu suchen
				Case 1
					$FileList = _FileListToArray(@scriptdir,'*s3db',1)
					If IsArray($FileList) and UBound($FileList) >= 2 Then
						$pf_database = @scriptdir&'\'&$FileList[1]
					Else
						ContinueCase
					endif

				;DB wird im Arbeitsspeicher angelegt.
				Case 2
					$pf_database = ':memory:'
					ConsoleWrite('<-- Datenbank wurde im Arbeitsspeicher erstellt'&@crlf)
			EndSwitch
		endif

	;----------------------------------------------------------------------------------------------/
	; Erstelle Connection
	;----------------------------------------------------------------------------------------------/
		Switch $action
			Case 'get'
				if IsHWnd($oConnection) = 0 then 
					ContinueCase
				endif
				return $oConnection

			Case 'create'
				if $dbStartup = False then 
					_SQLite_Startup($pf_sqLiteDll)
						If @error Then return SetError(1,'','SQLite3.dll kann nicht geladen werden!')
					$dbStartup = True
				endif

				$oConnection = _SQLite_Open($pf_database)				
					If @error Then return SetError(1,'','Kann keine Datenbank im Speicher erstellen!')
				return $oConnection
			
			Case 'close'
				_SQLite_Shutdown()
		EndSwitch
endfunc


;----------------------------------------------------------------------------------------------/
; Beschreibung: = Get Verweis auf __m_SQLite_query
;
; Update        = 20.02.2015		
; von           = 4ern.de
;----------------------------------------------------------------------------------------------/
func __mSQlite_getQuerry($param)
	$ret = __m_SQLite_query($param,'get')
	return SetError(@error, '', $ret)
endfunc ;<==/newFunc

;----------------------------------------------------------------------------------------------/
; Beschreibung: = Set Verweis auf __m_SQLite_query
;
; Update        = 20.02.2015		
; von           = 4ern.de
;----------------------------------------------------------------------------------------------/
func __mSQlite_setQuerry($param)
	$ret = __m_SQLite_query($param,'set')
	return SetError(@error, '', $ret)
endfunc ;<==/newFunc

;----------------------------------------------------------------------------------------------/
; Beschreibung: = Ermittelt / Schreibt / Ändert oder löscht Daten in der Datenbank
;
; Info 			= Siehe Dokumentation
;				  https://github.com/4ern/AutoIt-SQLite-Helper/edit/master/README.md
;
; Update        = 30.10.2014
; von           = 4ern.de
;----------------------------------------------------------------------------------------------/
func __m_SQLite_query($query, $action = 'get')

	Local $ergebnis, $zeile, $spalten
	Local $timestamp_format = 0

	;----------------------------------------------------------------------------------------------/
	; Umlaut Catcher!
	;----------------------------------------------------------------------------------------------/
		Local Static $aUmlaute [][] = 	[ _
											['Umlaut', 'Ubersetzung'], _
											['Ä','Ae'], _
											['Ö','Oe'], _
											['Ü','Ue'], _
											['ä','ae'], _
											['ö','oe'], _
											['ü','ue'], _
											['ß','?s']  _
										]

	;----------------------------------------------------------------------------------------------/
	; Hollt das DB Handel
	;----------------------------------------------------------------------------------------------/
		$oDatabase = __m_SQLite_Constructor('get')

	;----------------------------------------------------------------------------------------------/
	; GET or SET Methoden
	;----------------------------------------------------------------------------------------------/
		switch $action
			Case 'get'

				;----------------------------------------------------------------------------------------------/
				; magic Datum
				;----------------------------------------------------------------------------------------------/
					$aRegEx  = StringRegExp($query, '\{(where*::.*)\}',3)
					if isarray($aRegEx) <> 0 then
						$replace = '{'&$aRegEx[0]&'}'
						$aSplit  = StringSplit((StringSplit($aRegEx[0], '::',2))[2], '->', 2)
						$adate   = StringSplit($aSplit[2],'.',2)
						$sdate   = $adate[2]&'-'&$adate[1]&'-'&$adate[0]
						$string  = 'where '&$aSplit[0]&' >= date("'&$sdate&'") ORDER BY '&$aSplit[0]&' ASC Limit 1'
						$query   = StringReplace($query, $replace, $string)
					endif

				;----------------------------------------------------------------------------------------------/
				; Magic Date Converter
				;----------------------------------------------------------------------------------------------/
				
					$aRegEx = StringRegExp($query, '\{(\w*::.*)\}',3)
					for $i = 0 to Ubound($aRegEx) -1
						
						$replace = '{'&$aRegEx[$i]&'}'
						$aSplit = StringSplit($aRegEx[$i], '::',1)
						$newRow = $aSplit[1]
						
						if StringInStr($aRegEx[$i], '->') <> 0 then 
							$newRow = StringStripWS((StringSplit($aSplit[2], '->',1)[2]), 3)
							$aSplit[2] = StringReplace($aSplit[2], '->', '',1)
							$aSplit[2] = StringReplace($aSplit[2], $newRow, '',1)
							$aSplit[2] = StringStripWS($aSplit[2], 3)						
						endif

						$spalte = $aSplit[1]
						$date = $aSplit[2]

						$date = StringReplace($date, 'dd', '%d.',1,1)
						$date = StringReplace($date, 'mm', '%m',1,1)
						$date = StringReplace($date, 'yyyy', ' %Y ',1,1)
						$date = StringReplace($date, 'HH', '%H',1,1)
						$date = StringReplace($date, 'MM', '%M',1,1)
						$date = StringReplace($date, 'SS.SSS', '%f',1,1)
						$date = StringReplace($date, 'SS', '%S',1,1)
						$string = 'strftime("'&$date&'",'&$spalte&') as '&$newRow
						$query = StringReplace($query, $replace, $string)	
					next			

				;----------------------------------------------------------------------------------------------/
				; Setze Umlaute
				;----------------------------------------------------------------------------------------------/
					for $i = 1 to Ubound($aUmlaute) -1
						$query = StringReplace($query, $aUmlaute[$i][0], $aUmlaute[$i][1],0,1)
					next

				;----------------------------------------------------------------------------------------------/
				; Führe SQL aus
				;----------------------------------------------------------------------------------------------/
					_SQLite_GetTable2d($oDatabase, $query, $ergebnis, $zeile, $spalten)
					$err = @error
					_SQLite_Close($oDatabase)

				;----------------------------------------------------------------------------------------------/
				; Setze Umlaute
				;----------------------------------------------------------------------------------------------/
					for $i = 1 to Ubound($aUmlaute) -1
						for $ii = 0 to Ubound($ergebnis) -1
							for $iii = 0 to Ubound($ergebnis,2) -1
								$ergebnis[$ii][$iii] = StringReplace($ergebnis[$ii][$iii], $aUmlaute[$i][1], $aUmlaute[$i][0],0,1)
							next
						next
					next

				;----------------------------------------------------------------------------------------------/
				; Gebe Datum im deutschen Format aus.
				;----------------------------------------------------------------------------------------------/
					for $i = 0 to Ubound($ergebnis) -1
						for $ii = 0 to Ubound($ergebnis,2) -1
							$aRegEx = StringRegExp($ergebnis[$i][$ii], '(?:199[0-9]|20[0-9][0-9])-(?:0[1-9]|1[0-2])-(?:[0-2][0-9]|3[0-1])',3)
							if IsArray($aRegEx) = 0 then ContinueLoop
							$aString = StringSplit($aRegEx[0], '-',2)
							$ergebnis[$i][$ii] = StringReplace($ergebnis[$i][$ii], $aRegEx[0], $aString[2]&'.'&$aString[1]&'.'&$aString[0])
						next
					next

				;----------------------------------------------------------------------------------------------/
				; Return
				;----------------------------------------------------------------------------------------------/
					return SetError($err, '', $ergebnis)
					
			Case 'set'

				;----------------------------------------------------------------------------------------------/
				; Timstamp Magic Function
				;----------------------------------------------------------------------------------------------/
					$timestamp = @year&'-'&@mon&'-'&@mday&'T'&@hour&':'&@min&':'&@sec&'.'&@MSEC
					$query = StringReplace($query, '{timestamp}', $timestamp)

				;----------------------------------------------------------------------------------------------/
				; Date Magic Function
				;----------------------------------------------------------------------------------------------/
					$aRegEx = StringRegExp($query, '\{(.*?)\}',3)
					for $i = 0 to Ubound($aRegEx) -1
						$replace = '{'&$aRegEx[$i]&'}'

						if StringRegExp($aRegEx[$i], '^([0-3]\d|[1-9])\.([0-3]\d|[1-9])\.(\d{4}|\d{2})$') = 0 then ContinueLoop
						$aSplit = StringSplit($aRegEx[$i], '.',2)

						$string = $aSplit[2] &'-'& $aSplit[1] &'-'& $aSplit[0]
						$query = StringReplace($query, $replace, $string)
					next

				;----------------------------------------------------------------------------------------------/
				; Setze Umlaute
				;----------------------------------------------------------------------------------------------/
					for $i = 1 to Ubound($aUmlaute) -1
						$query = StringReplace($query, $aUmlaute[$i][0], $aUmlaute[$i][1], 0, 1)
					next

				;----------------------------------------------------------------------------------------------/
				; Führe SQL aus
				;----------------------------------------------------------------------------------------------/
					$ret = _SQLite_Exec($oDatabase,$query)
					$err = @error
					_SQLite_Close($oDatabase)

				;----------------------------------------------------------------------------------------------/
				; Return
				;----------------------------------------------------------------------------------------------/
					return SetError($err, '', $ret)
		Endswitch
endfunc ;<==/m_database_query


;----------------------------------------------------------------------------------------------/
; Beschreibung: = Zeigt Informationen aus der SQLite DB an
;
; Info 			= Siehe Dokumentation
;				  https://github.com/4ern/AutoIt-SQLite-Helper/edit/master/README.md
;
; Update        = 23.02.2015
; von           = 4ern.de
;----------------------------------------------------------------------------------------------/
func __mSqlite_Information($display = 'console')
	
	Local $oDatabase               = __m_SQLite_Constructor()
	Local $sql_version             = _SQLite_LibVersion()
	Local $changes_without_trigger = _SQLite_Changes($oDatabase)
	Local $changes_with_trigger    = _SQLite_TotalChanges($oDatabase)
	Local $last_error_Code         = _SQLite_ErrCode($oDatabase)
	Local $last_error_msg          = _SQLite_ErrMsg($oDatabase)
	Local $pfad_DB                 = __m_SQLite_Constructor('pf_database')
	Local $pfad_dll                = __m_SQLite_Constructor('pf_sqLiteDll')
	
	Switch $display
		Case 'array'
			Local $array[][] = [ _
				['Version',$sql_version], _
				['Veränderungen ohne Trigger',$changes_without_trigger], _
				['Veränderungen mit Trigger',$changes_with_trigger], _
				['Letzter Fehler-Code',$last_error_Code], _
				['Fehler Nachricht',$last_error_msg], _ 
				['Verzeichnis Datenbank',$pfad_DB], _
				['Verzeichnis SQLite3.dll',$pfad_dll] _
				]
				_ArrayDisplay($array)
		Case 'console'
			ConsoleWrite( _
				'<--- SQLite Information !!!!' & _
				'SQLite Version: ' & $sql_version & @crlf & @crlf & _
				'Veränderungen ohne Trigger: '& $changes_without_trigger & @crlf & _
				'Veränderungen mit Trigger: '& $changes_with_trigger & @crlf & @crlf & _
				'Letzter Fehler-Code:' & $last_error_Code & @crlf & _
				'Fehler Nachricht: ' &$last_error_msg & @crlf & @crlf & _
				'Verzeichnis Datenbank: ' &$pfad_DB & @crlf & _
				'Verzeichnis SQLite3.dll: ' &$pfad_dll & @crlf & _
				'!!! SQLite Information --->')
		Case 'msg'
			MsgBox(48, 'SQLite Information', _
				'SQLite Version: ' & $sql_version & @crlf & @crlf & _
				'Veränderungen ohne Trigger: '& $changes_without_trigger & @crlf & _
				'Veränderungen mit Trigger: '& $changes_with_trigger & @crlf & @crlf & _
				'Letzter Fehler-Code: ' & $last_error_Code & @crlf & _
				'Fehler Nachricht: ' &$last_error_msg & @crlf & @crlf & _
				'Verzeichnis Datenbank: ' &$pfad_DB & @crlf & _
				'Verzeichnis SQLite3.dll: ' &$pfad_dll & @crlf)
	EndSwitch	
endfunc ;<==/_mSqlite_Information

;----------------------------------------------------------------------------------------------/
; Beschreibung: = Setzt ein Flag in die Tabelle und übermittelt die geflaggten Daten
;
; Info 			= Siehe Dokumentation
;				  https://github.com/4ern/AutoIt-SQLite-Helper/edit/master/README.md
;
; Update        = 23.02.2015
; von           = 4ern.de
;----------------------------------------------------------------------------------------------/
func __mSqlite_getSetFlag($table = '' ,$such_Wert = '', $flag_spalte = '', $flag_wert = '')
	
	if $table       = '' then $table       = __mSqlite_defaults('tabelle')
	if $such_Wert   = '' then $such_Wert   = __mSqlite_defaults('suchewert')
	if $flag_spalte = '' then $flag_spalte = __mSqlite_defaults('flag_spalte')
	if $flag_wert   = '' then $flag_wert   = __mSqlite_defaults('flag_wert')

	;gesetzten Flag lesen
	$sql = 'SELECT * FROM '&$table&' where '&$flag_spalte&' = "'&$flag_wert&'" LIMIT 1;'
	$ret = __m_SQLite_query($sql,'get')
	If IsArray($ret) = 1 and UBound($ret) >= 2 Then
		return SetError(@error, '', $ret)
	endif

	;Flag setzen
	$sql = 'UPDATE '&$table&' SET '&$flag_spalte&' ="'&$flag_wert&'" WHERE id in (SELECT id FROM '&$table&' WHERE '&$flag_spalte&' = "'&$such_Wert&'" LIMIT 1);'
	$ret = __m_SQLite_query($sql,'set')
		if @error then return SetError(@error, '', $ret)

	;gesetzten Flag lesen
	$sql = 'SELECT * FROM '&$table&' where '&$flag_spalte&' = "'&$flag_wert&'" LIMIT 1;'
	$ret = __m_SQLite_query($sql,'get')
	If IsArray($ret) = 1 and UBound($ret) >= 2 Then
		return SetError(@error, '', $ret)
	Else
		ConsoleWrite('<--- Suchwert: "'&$such_Wert&'" konnte in der Tabelle: "'&$table&'" und Spalte: "'&$flag_spalte&'" nicht ermittelt werden' & @crlf)
		return SetError(1, '', '0')
	endif
endfunc ;<==/_mSqlite_getSetFlag

;----------------------------------------------------------------------------------------------/
; Beschreibung: = SQLite Defaults
;
; Info 			= Siehe Dokumentation
;				  https://github.com/4ern/AutoIt-SQLite-Helper/edit/master/README.md
;
; Update        = 25.02.2015	
; von           = 4ern.de
;----------------------------------------------------------------------------------------------/
func  __mSqlite_defaults($_strVarName, $_value='', $_action='get')

	Local Static $oDict = ObjCreate('Scripting.Dictionary')
	Local Static $1stStart = 0

	If $1stStart = 0 Then
		$oDict.Add('tabelle', 'data') ;Standard Tabelle
		$oDict.Add('spalte', 'state') ;Standard Spalte
		$oDict.Add('suchewert', 'open') ;Nach Welchen Wert soll die Spalte durch sucht werden
		$oDict.Add('flag_spalte', 'flag') ;Spalte in welche der Flag eingetragen werden soll
		$oDict.Add('flag_wert', @computername) ;Wert welcher in die Flag Spalte geschrieben wird
		$1stStart = 1
	EndIf
	
	Switch $_action
	Case 'get'
	    If $oDict.Exists($_strVarName) Then
	        Return $oDict.Item($_strVarName)
	    Else
	        Return SetError(1,0,'')
	    EndIf
	Case 'set'
	    If Not $oDict.Exists($_strVarName) Then
	        $oDict.Add($_strVarName, $_value)
	    Else
	        $oDict.Item($_strVarName) = $_value
	    EndIf
	case 'display'
		$anzahl = $oDict.Count +1
		Local $array[$anzahl][2]
	    $colKeys = $oDict.Keys
	    $i = 0
		For $strKey in $colKeys
			$array[$i][0] = $strKey
			$array[$i][1] = $oDict.Item($strKey)
			$i += 1
		Next
		_ArrayDisplay($array)
	EndSwitch
endfunc ;<==/getSet_Salcus_Vars

;----------------------------------------------------------------------------------------------/
; Beschreibung: = Zählt die Zeilen anhand der übergeben Parameter
;
; Info 			= Siehe Dokumentation
;				  https://github.com/4ern/AutoIt-SQLite-Helper/edit/master/README.md
;
; Update        = 25.02.2015
; von           = 4ern.de
;----------------------------------------------------------------------------------------------/
func __mSqlite_count($table = '', $spalte = '', $such_Wert = '')
	
	if $table     = '' then $table 	= __mSqlite_defaults('tabelle')
	if $spalte    = '' then $spalte = __mSqlite_defaults('spalte')
	if $such_Wert = '' then $such_Wert = __mSqlite_defaults('suchewert')
	
	;gesetzten Flag lesen
	if $spalte = '' then
		$sql = 'SELECT count('*') FROM '&$table&';'
	Else
		$sql = 'SELECT count(*) FROM '&$table&' WHERE '&$spalte&' = "'&$such_Wert&'";'
	endif

	$ret = __m_SQLite_query($sql,'get')
		If IsArray($ret) = 1 and UBound($ret) >= 2 Then
			return SetError(@error, '', $ret[1][0])
		Else
			ConsoleWrite('<--- Suchwert: "'&$such_Wert&'" konnte in der Tabelle: "'&$table&'" und Spalte: "'&$spalte&'" nicht ermittelt werden' & @crlf)
			return SetError(1, '', '0')
		endif
endfunc ;<==/_mSqlite_count
