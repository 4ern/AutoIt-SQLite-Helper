*von 4ern.de*

*SQLite Helper erleichtert die arbeit mit SQLite Datenbank in Verbindung mit AutoIt*

#SQLite Helper#

Inhaltsverzeichnis
------------------

- SQL_Init
- SQL_defaults
- SQL_Get
- SQL_Set
- SQL_Info
- SQL_Flag

nächste Funktionen
- sql_create()

----------

###SQL Init###
>```AutoIt
> $sql_init([$param1 = 'string'])
>```
>Mit der Initialisierung hat man die Möglichkeit die Pfade für die SQLite3.dll und zu der Datenbank festzulegen. **Die Initialisierung ist Default und muss nicht zwingend aufgerufen werden.**

>**Regeln ohne Initialisierung**

 > 1. Script Ordner wird nach *s3db Dateien durchsucht. Erstes Vorkommen wird als Datenbank-Datei herangezogen.
 > 2. Wenn keine Datenbank im Scriptordner ermittelt werden konnte, wird eine Datenbank Temporär im Arbeitsspeicher angelegt.

>**Parameter**
>>`$param1` (optional) Pfad zur Datenbank

>**Beispiel**

>```ruby
>  $pf_db = 'C:\myDb.s3db' 
>  $sql_init($pf_db)
>```

###SQL Defaults###

>```AutoIt
> $sql_defaults($param1 = 'string',[$param2 = 'string'],[$param2 = 'string'])
>```
> Diese Funktion dient dazu um Parameterangben zu sparen um z. B. Tabellenname oder Spaltnamen vor zu deklarieren. 
> Diese Funktion sollte am Script anfang erfolgen.

>**Parameter**
>>`$param1` Name des Wertes
>> `$param2`(optional) Wert
>> `$param3`(optional) Durchzuführende Aktion  `'get' (default)`, `'set'` & `'display'`

>**Standard (Defaults)**
>>`Tabelle => data`
`spalte => state`
`suchwert => open`
`flag_Spalte => flag`
`flag_Wert => @computername`

>**Beispiel Default setzen**
>```AutoIt
> $sql_defaults('Tabelle','Mitarbeiter')
>```

>>`Tabelle => Mitarbeiter`

>**Beispiel Default lesen**
>
>```AutoIt
> $tabelle = $sql_defaults('Tabelle','','get')
>```
>>`Tabelle => Mitarbeiter`
>
>**Beispiel Defaults anzeigen**
>
>```AutoIt
> $sql_defaults('','','display')
>```
>>|Row|Col 0|Col 1
>|---|---|
>|[0]|tabelle|data
>|[1]|spalte|state
>|[2]|suchewert|open
>|[3]|flag_spalte|flag
>|[4]|flag_wert|DES*****

###SQL Get###
>```AutoIt
> $sql_get([$param = 'string'])
>```
>Führt eine SQL Abfrage aus. 
>**Diese Funktion konveniert automatisch Umlaute.**
>**Diese Funktion konveniert automatisch SQL Datum ins deutsche Format.**  `2015-02-24 => 24.02.2015`

>**Parameter**
>>`$param` SQL Abfrage String
>
>**Magic Funktionen (Datum & Zeit)**
>
>**Achtung:** Damit diese Magic Funktionen korrekt funktionieren, müssen die Felder in SQL den Format Timestamp oder Date haben.
>>`{timestamp::dd.mm.yyyy HH:MM:SS.SSS}` gibt die definierte Spalte `timestamp` im vorgegebenen Format aus. Mit dem optionalen Parameter `-> Spaltennamen` kann man der Spalte einen anderen Namen geben. Siehe Beispiel.
>

>>`{where::timestamp->24.02.2015}`Erstellt eine Teil SQL Abfrage, die es ermöglicht eine where Abfrage auf ein TimeStamp oder Datum anzuwenden. Siehe Beispiel.

>>`{datum}` konvertiert ein deutsches Datum in SQL Format

>>**Format:**
>>>**Groß - Kleinschreibung muss beachtet werden (Case Sensitive)**

>>`dd` = Tag

>>`mm` = Monat

>>`yyyy` = Jahr

>>`HH` = Stunde

>>`MM` = Minuten

>>`SS` = Sekunden

>>`SS.SSS` = Milisekunden


>>**Beispiele Magic Function Time & Date:**

>>**PS: 'timestamp' -> ist der Name der Timestamp Spalte in der Datenbank**
>```ruby
> $sql_get('SELECT {timestamp::dd.mm.yyyy HH:MM:SS} from data')
> $sql_get('SELECT {timestamp::HH:MM:SS -> Zeit} from data')
> $sql_get('SELECT {timestamp::dd.mm.yyyy -> Datum} from data')
>$sql_get('SELECT {timestamp::HH:MM -> zeit} from data where date = {21.02.2015}')
>$sql_get('SELECT {timestamp::HH:MM:SS -> Zeit} from data {where::timestamp->20.01.2015};')
>```

>>**Ausgabe SQL STRING**

>`SELECT strftime("%d.%m %Y  %H:%m:%S",timestamp) as timestamp from data;`

> `SELECT strftime("%H:%m:%S",timestamp) as Zeit from data;`

> `SELECT strftime("%d.%m %Y",timestamp) as Datum from data;`

> `SELECT strftime("%H:%m:%S",timestamp) as Zeit from data where date = 2015-02-21;`

> `SELECT strftime("%H:%M:%S",timestamp) as Zeit from data where timestamp >= date("2015-01-20") ORDER BY timestamp ASC Limit 1;`


>**@error**

>>`-1` SQLite meldet einen Fehler (prüfe Rückgabewert)

>>`1` Fehler beim Aufruf von _SQLite_Query

>>`2` Fehler beim Aufruf der SQLite API 'sqlite3_free_table'

>>`3` Ausführung verhindert durch Sicherheitsmodus

>>`4` Abbruch, Trennung oder @error gesetzt durch ein Callback (@extended wird auf einen SQLite Fehler gesetzt)

>**Beispiel**
>>```AutoIT
>  $sql = 'SELECT * FROM data' 
>  $aDatan = $sql_get($sql )
 >  _arrayDisplay($aDatan)
>```
>>**Ausgabe**

>>| Row | Col 0 | Col 1 | Col 2 | Col 3 | Col 4 |
>>| ------------- | ------------- | ------------- | ------------- | ------------- | ------------- |
>>| [0] | ID | Acc | Gutschrift| State| Timestamp |
>>| [1] | 1 | 123 | 9,99 | open | 2015-02-19 15:02:44.811 |
>>| [2] | 2 | 321 | 9,99 | open | 2015-02-19 15:03:11.898 |
>>| [3] | 3 | 455 | 9,99 | open | 2015-02-19 16:46:45.900 |
>>| [4] | 4 | 554 | 9,99 | open | 2015-02-19 15:03:38.888 |
>>| [5] | 5 | 698 | 9,99 | open | 2015-02-19 15:04:05.889 |

###SQL Set###
>```AutoIt
> $sql_set([$param = 'string'])
>```
>Führt eine SQL Ausführung aus. **Diese Funktion konvertiert automatisch Umlaute.**

>**Parameter**
>>`$param` SQL Ausführungs String

>**Magic Funktionen**
>>`{datum}` konvertiert ein deutsches Datum in SQL Format
>
>>**Beispiel:**
>```AutoIt
>$sql = 'UPDATE data SET date= {24.02.2015} where id = 3'
> $sql_set($sql)
>```
>>**Ausgabe**
>`'UPDATE data SET date= 2015-02-24 where id = 3'`

>**@error**

>>`-1` SQLite hat einen Fehler festgestellt (Rückgabewert überprüfen)

>>`1` Fehler beim Aufruf des SQLite API 'sqlite3_exec'

>>`2` Aufruf vom Sicherheitsmodus verhindert

>>`3` Fehler in der Callback-Funktion von _SQLite_GetTable2d

>>`4` Fehler beim konvertieren des SQL-Auszuges in UTF-8


>**Beispiel**
>>``` AutoIt
>  $sql = 'Update data SET state = "done" WHERE id = 4 
>  $sql_set($sql)
>```

###SQL Info###
>```AutoIt
> $sql_info([$param = 'string'])
>```
> Zeigt Informationen zur aktuellen Datenbank

>**Parameter**
>>`'console'` (Default) Zeigt die Informationen in der Console an.
>>`'msg'` Zeigt die Informationen in der Messagebox an.
>>`'array'` Zeigt ein Array mit den Informationen an.

>**Informationen**
>>- Version
> - Veränderungen ohne Trigger
> - Veränderungen mit Trigger
> - Letzter Fehler-Code
> - Fehler Nachricht
> - Verzeichnis Datenbank
> - Verzeichnis SQLite3.dll

>**Beispiel**
>>```AutoIT
>  $sql_info('array')
>```
>>**Ausgabe**

>>| Row| Col 0 | Col 1 |
>>| ------------- | ------------- | ------------- |
>>| [0] | Version | 0 |
>>| [1] | Veränderungen ohne Trigger | 0 |
>>| [2] | Veränderungen mit Trigger | 0 |
>>| [3] | Letzter Fehler-Code | 21 |
>>| [4] | Fehler Nachricht | Library used incorrectly |
>>| [5] | Verzeichnis Datenbank | K:\CRS\Entwicklung\CCN\eddi\Projekte\AutoIt\BillClear\billclear.s3db |
>>| [6] | Verzeichnis SQLite3.dll | K:\CRS\Entwicklung\CCN\eddi\Projekte\AutoIt\BillClear\SQLite3.dll |

###SQL Flag###
>```AutoIt
> $sql_flag([$param1 = 'string'],[$param2 = 'string'],[$param3 = 'string'],[$param4 = 'string'])
>```
> Setzt in der Datenbank ein Flag auf einen Datensatz, und übergibt diesen in ein Array.  Es wird hierbei nur das erste Vorkommen behandelt. **Dies ist Sinnvoll wenn mehrer PC's mit einer Datenbank arbeiten.**

>**Parameter** *kompatibel mit [$sql_defaults](#sql-defaults)*

>>`$param1` = `(Default => tabelle)` Tabellenname 

>>`$param2` = `(Default => suchewert)` Wert nach welchen gesucht werden soll

>>`$param3` = `(Default => flag_spalte)` Name der Tabellenspalte in welcher der Flag erfolgen soll 

>>`$param4` = `(Default => flag_wert)` Wert des Flags 

>**@error**
>> siehe Error bei `$sql_set()` & `$sql_get()`

>**Beispiel**
>>mit Defaults
>```AutoIT
>  $aDatan = $sql_flag()
>  _arrayDisplay($aDatan)
>```

>>ohne Defaults
>>```autoit
>  $aDatan = $sql_flag('data','open','flag', @computername)
>  _arrayDisplay($aDatan)
>```
>>**Ausgabe**

>>| Row | Col 0 | Col 1 |Col 2 | Col 3 | Col 4 | Col 5 |
>>| ------------- | ------------- | ------------- | ------------- | ------------- | ------------- | ------------- |
>>| [0] | ID | Acc | Gutschrift | State | Flag | Timestamp |
>>| [3] | 3 | 123 | 9,99 |open | Computer | 19.02.2015 16:46:45.900 |

###SQL Count###

>```AutoIt
> $sql_count([$param1 = 'string'], [$param2 = 'string'],[$param3 = 'string'])
>```
>liefert die Spalten Anzahl anhand des gesuchten Wertes

>**Parameter** *kompatibel mit [$sql_defaults](#sql-defaults)*

>>`$param1` = `(Default => tabelle)` *optional* Tabellen Name

>>`$param2` = `(Default => spalte)` *optional* Spalten Name

>>`$param3` = `(Default => suchwert)` *optional* Suchwert

>**Beispiel mit Defaults**
>```AutoIt
>  $count = $sql_count()
>```
>**Ausgabe**
>`20`

>**Beispiel ohne Defaults**
>```AutoIt
>  $count = $sql_count('data','state','open')
>```
>**Ausgabe**
>`20`
