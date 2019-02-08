--Maciej Kasprzyk projekt bazy danych

set serveroutput on;

-----------tworzenie tabel----------------------------------
DROP TABLE clients cascade constraints;
DROP TABLE orders cascade constraints;
DROP TABLE products cascade constraints;
DROP TABLE deliver cascade constraints;
DROP TABLE orders_products cascade constraints;
DROP TABLE deliver_products cascade constraints;

CREATE TABLE clients (
    id int,
    lastName varchar(255) NOT NULL, 
    firstName varchar(255) NOT NULL,
    street varchar(255),
    houseNumber int,
    city varchar(255), 
    flatNumber int,
    bonusPoints int,
    constraint con1 primary key (id)
);

CREATE TABLE orders(
    id int,
    dateOfPlacement date,
    clientID int not null,
    constraint con2 foreign key (clientID) references clients(id),
    constraint con3 primary key (id)
);

CREATE TABLE products(
    id int,
    name varchar(255),
    quanity int,
    price int,
    constraint con4 primary key (id)
);

CREATE TABLE deliver(
    id int,
    supplierName varchar(255),
    dateOfDeliver date,
    constraint con5 primary key (id)
);


CREATE TABLE orders_products(
    orderID int NOT NULL,
    productID int NOT NULL,
    quanity int,
    constraint con6 FOREIGN KEY (orderID) REFERENCES orders(id),
    CONSTRAINT con7 foreign KEY (productID) references products(id)
);

CREATE TABLE deliver_products(
    deliverID int NOT NULL,
    productID int NOT NULL,
    quanity int,
    constraint con8 FOREIGN KEY (deliverID) REFERENCES deliver(id),
    CONSTRAINT con9 foreign KEY (productID) references products(id)
);

-----------wszystko co potrzebne do autoinkrementacji id tzn. procedura resetujaca, sekwencje oraz triggery
create or replace procedure reset_seq( seq_name in varchar2 )
is
    seq_max number;
begin
    execute immediate
    'select ' || seq_name || '.nextval from dual' into seq_max;
    execute immediate
    'alter sequence ' || seq_name || ' increment by -' || seq_max || ' minvalue 0';
    execute immediate
    'select ' || seq_name || '.nextval from dual' into seq_max;
    execute immediate
    'alter sequence ' || seq_name || ' increment by 1 minvalue 0';
end;
/

drop sequence clients_seq;
drop sequence orders_seq;
drop sequence products_seq;
drop sequence deliver_seq;

CREATE SEQUENCE clients_seq START WITH 1 INCREMENT BY 1 NOMAXVALUE;
CREATE SEQUENCE orders_seq START WITH 1 INCREMENT BY 1 NOMAXVALUE;
CREATE SEQUENCE products_seq START WITH 1 INCREMENT BY 1 NOMAXVALUE;
CREATE SEQUENCE deliver_seq START WITH 1 INCREMENT BY 1 NOMAXVALUE;

CREATE OR REPLACE TRIGGER clients_id_trigger
BEFORE INSERT ON clients
FOR EACH ROW
BEGIN
    SELECT clients_seq.nextval INTO :new.id FROM dual;
END;
/
CREATE OR REPLACE TRIGGER orders_id_trigger
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
    SELECT orders_seq.nextval INTO :new.id FROM dual;
END;
/
CREATE OR REPLACE TRIGGER products_id_trigger
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    SELECT products_seq.nextval INTO :new.id FROM dual;
END;
/
CREATE OR REPLACE TRIGGER deliver_id_trigger
BEFORE INSERT ON deliver
FOR EACH ROW
BEGIN
    SELECT deliver_seq.nextval INTO :new.id FROM dual;
END;
/

-----------deklaracja triggerow uzywanych w tabelach---------------------------
--------------------------------------------------------------------------------
--------------ten trigger dolicza kazdemu klientowi punkty w zaleznosci od wartosci zamowionych przez niego projektów oraz zmniejsza dostepna ilosc produktow w magazynie
create or replace
trigger trigger_orders_products
before insert on orders_products
for each row
declare

    price int;
    clientIDD int;
    newQuanity int;
begin
    
    --obliczamy nowy stan magazynowy aby sprawdzic czy nie bedzie ujemny
    select quanity into newQuanity
    from products
    where id = :new.productID;
    newQuanity := newQuanity - :new.quanity;
    
    --jezelie ilosc bylaby mniejsza niz zero to wylatujemy na bledzie
    IF newQuanity < 0 THEN
        Raise_Application_Error (-20343, 'Nie ma wystarczającej ilości produktów na magazynie.');
    END IF;
    
    --odszukujemy ceny zamawianego towaru w tabeli products na podstawie productID
    select p.price into price from products p where p.id= :new.productID;
    --odszukujemy id clienta w tabeli orders na podstawie orderID
    select orders.clientID into clientIDD from orders where orders.id= :new.orderID;
    
    --aktualizujemy punkty bonusowe klineta
    update clients
    set bonusPoints = bonusPoints+ :new.quanity * price
    where id = clientIDD;
    
    --aktulizujemy stan magazynowy
    update products
    set quanity = quanity - :new.quanity
    where id = :new.productID;
end  trigger_orders_products;
/



-----------------------------------------------------------------------------------
------------------------ten trigger zmniejsza ilosc dostepnych produktow w magazynie

create or replace
trigger trigger_deliver_products
before insert on deliver_products
for each row
declare
begin
    update products
    set quanity = quanity + :new.quanity
    where id = :new.productID;
end  trigger_orders_products;
/


------------------------deklaracja procedur generujacych dane

--funkcja używana do losowania, aby było mniej pisania
CREATE OR REPLACE FUNCTION rand(N IN NUMBER)
RETURN NUMBER 
AS 
BEGIN
    RETURN TRUNC (DBMS_RANDOM.VALUE(1, n));
END rand;
/

CREATE OR REPLACE PROCEDURE gen_clients IS 
    lastName varchar(255);
    firstName varchar(255);
    street varchar(255);
    houseNumber int;
    city varchar(255);
	flatNumber int;
    
    TYPE tabstr IS TABLE OF VARCHAR2(255);
    lastNames tabstr;
    firstNames tabstr;
    streets tabstr;
    cities tabstr;
BEGIN
    lastNames := tabstr('Byczek','Janik','Pawlas','Rykowski','Andrzejczuk','Magdziak','Skrzypiński','Podolski','Abramowski','Kaca','Giemza','Antosik','Kęski','Stawiarski','Szlaga','Surowiec','Niemczyk','Tomaszek','Dzwonek','Skałecki','Zaleski','Krogulec','Falkiewicz','Słotwiński','Gaweł','Stachyra','Krzywda','Dyjak','Orłowski','Malec','Stryczek','Zelek','Topolewski','Wrzesień','Pawlus','Klepacki','Skrok','Dolata','Ługowski','Grzeszczak','Grzesiuk','Gniadek','Piątek','Kawczyński','Osak','Maćkiewicz','Choma','Możejko','Wojtecki','Olczak','Tyszko','Zapart','Zuber','Filipczak','Borzyszkowski','Szumski','Książek','Piekarski','Mizerski','Kubica','Zimna','Schneider','Lenkiewicz','Gąsior','Korol','Próchniak','Świętochowski','Łukawski','Soćko','Fluder','Bakalarz','Łagowski','Ligocki','Górny','Poznański','Dmochowski','Grzywiński','Jarzębski','Oniszczuk','Jeż','Mleczko','Studnicki','Chądzyński','Niziołek','Majcher','Garstka','Łuszczyński','Orczyk','Piecha','Kufel','Janaszek','Fischer','Kulesza','Sobieraj','Zarębski','Kubicz','Waga','Wardęga','Fajfer','Papież','Zalas','Dziadek','Dziekoński','Kazanowski','Kochanowski','Wroński','Stanisławski','Twaróg','Zgoda','Chudziński','Miś','Myszkowski','Kubera','Durak','Staś','Pawełek','Kuczera','Kasperczyk','Dzik','Bocian','Gąsowski','Seroczyński','Spychalski','Baczyński','Stanik','Kazimierski','Igielski','Izdebski','Deka','Komosa','Kalus','Hibner','Szczerba','Kulak','Zgierski','Kawalec','Filipczuk','Litwin','Pucek','Jarecki','Ceglarz','Rózga','Stróżyński','Dudka','Cuper','Zwierzyński','Gonciarz','Rybicki','Duszyński','Kostrubiec','Wrzeszcz','Korczyk','Kupisz','Gibas','Trojnar','Tatara','Zakrzewski','Joachimiak','Świąder','Olszowy','Winiarz','Kalita','Just','Romanowski','Smaga','Wątroba','Dynowski','Gondek','Rychlicki','Soszyński','Jędryka','Drapała','Zemła','Martyniak','Skowroński','Karaś','Boczek','Wojtyła','Tracz','Kunc','Remiszewski','Plata','Giziński','Karpiński','Kołecki','Kuczek','Dombrowski','Sadowski','Kadłubowski','Cabaj','Iwański','Małek','Cicha','Bagrowski','Pierzchała','Gapski','Smolik','Jędrysiak','Romański','Ogórek','Falkowski','Kmita','Deja','Durzyński','Fudała','Orzechowski','Kotlarz','Skuza','Fabisiak','Słomczyński','Wiatrowski','Mocek','Pieczka','Malczewski','Buczyński','Chomicz','Niewiadomski','Korona','Galiński','Frączkowski','Sokalski','Staniak','Szulik','Kobus','Grygoruk','Doniec','Kwaśny','Bieniasz','Jadach','Marut','Danielczyk','Przychodzeń','Piętak','Bura','Wicik','Dyba','Przybyłowicz','Jamrozik','Łysik','Żuber','Bidziński','Szewczyk','Masternak','Zajkowski','Szatkowski','Gębala','Kata','Ząbek','Krzemień','Koziołek','Marzec','Krasiński','Chorąży','Tkaczuk','Świtalski','Budny','Rewers','Kuźniak','Jaszczyk','Perz','Stefan','Pluta','Tarasiuk','Pakulski','Ogrodowski','Czech','Kuryło','Kłosiński','Kwaśna','Kurzawski','Wika','Pajda','Knop','Lubczyński','Sułkowski','Konefał','Rostkowski','Schulz','Siuta','Rzeźnik','Witczak','Golik','Jakimowicz','Lemańczyk','Płaza','Dyl','Swoboda','Michałek','Boguszewski','Gruchała','Grzegorczyk','Wolski','Wilczewski','Bogucki','Pych','Ujma','Bania','Kostecki','Fortuna','Tomkiewicz','Sadłowski','Starczewski','Polanowski','Gałek','Burakowski','Meyer','Uliński','Biela','Siczek','Sulewski','Adamczewski','Kościelna','Mocarski','Papis','Borek','Komorek','Syrek','Arciszewski','Jakubas','Grzęda','Sawicki','Szynal','Gibała','Błasiak','Barylski','Byrski','Sojka','Kraus','Sędłak','Dłużniewski','Dolatowski','Gołuch','Ciechomski','Nowotarski','Dobrowolski','Patyk','Kowal','Nawrot','Daniszewski','Wilkosz','Dobosz','Glinka','Winiarski','Kucia','Łada','Dutkowski','Perliński','Bartyzel','Lupa','Grabarz','Luty','Korcz','Białek','Walczak','Kuśnierz','Laskowski','Karliński','Madaliński','Kopecki','Gołąb','Fedorowicz','Brzezina','Sulkowski','Andrzejczyk','Dobies','Kuźniar','Kopczyński','Łęcki','Czarnik','Kupczak','Zawadka','Lendzion','Czarniecki','Ozimek','Bączyk','Danielak','Krakowski','Piechocki','Postek','Frankiewicz','Jaworek','Staszek','Czogała','Babiak','Wrona','Dymiński','Demianiuk','Kwieciński','Dobrzycki','Baryła','Stasiewicz','Błaszak','Małachowski','Grabka','Krok','Suchecki','Płonka','Gontarczyk','Urbanowski','Kwolek','Kilian','Walczyński','Kornas','Bukowiecki','Niklas','Dmowski','Krzymiński','Pawlica','Majcherek','Furgał','Wierciński','Brzezicki','Antos','Bieszczad','Łuba','Łyczkowski','Pilarz','Tomczyk','Jurasz','Borowiak','Sulowski','Kubiczek','Płachta','Szreder','Fudali','Szymura','Moroz','Grzymała','Kaliński','Kasztelan','Paździor','Rynkowski','Michalczuk','Kosiorek','Rzepecki','Wojewódzki','Kuca','Korczak','Michna','Bucki','Janek','Załęcki','Okrasa','Majchrzak','Wiącek','Korytkowski','Łupiński','Berezowski','Ludwikowski','Zawistowski','Dołęga','Foltyn','Woźniak','Banach','Wojnowski','Jaruga','Leszko','Jeznach','Grabowicz','Krzyżanowski','Plewa','Sosna','Bazan','Krajewski','Bieńko','Rajkowski','Trzciński','Langner','Dolna','Łaski','Jureczko','Matuszek','Dyrda','Stolarek','Roguski','Pałka','Skupień','Iwaszko','Sobczyński','Ptasiński','Osowski','Pol','Widawski','Dyląg','Zaręba','Kiliński','Rączka','Półtorak','Piszcz','Tkacz','Werner','Czernecki','Ważny','Arndt','Spychała','Świerczewski','Trzaski','Kukliński','Noworyta','Miazga','Adamczuk','Goździewski','Krzyżewski','Tymiński','Korneluk','Pisula','Możdżeń','Błędowski','Szydłowski','Kawałek','Mrugała','Bochenek','Siemianowski','Małyszko','Mnich','Labuda','Śnieżek','Kamrowski','Czerw','Mielnicki','Szuster','Pogoda','Śledziewski','Rojewski','Nycz','Skrobisz','Żądło','Sierant','Boczkowski','Zwierz','Niewiński','Ryszkowski','Pyrka','Grochala','Badowski','Pięta','Kowalczuk','Żabicki','Wnuk','Iwaszkiewicz','Wojda','Kulczycki','Kosik','Krysiak','Golba','Dybowski','Jarząb','Urbanik','Rogaczewski','Kijowski','Orzech','Bielec','Szady','Słonina','Czerwiec','Kalemba','Bochen','Goraj','Bogacz','Abramek','Kostuch','Kulpa','Urbański','Juraszek','Dziedzic','Sokólski','Wiktor','Będkowski','Starowicz','Potępa','Szota','Przyborowski','Pęcak','Bobowski','Ordon','Cisek','Warszawski','Podsiadły','Sitko','Wojtala','Wożniak','Tymoszuk','Bajkowski','Karczmarczyk','Zduniak','Jachimowski','Chałupka','Hajduk','Michałowski','Jackowiak','Porowski','Rudowski','Struk','Burczyk','Bujalski','Jacewicz','Wójtowicz','Stachura','Rumiński','Majkowski','Zoń','Czernek','Jaczewski','Gruszka','Krawczuk','Gaca','Dembowski','Piontek','Łukowski','Jodłowski','Wandzel','Sikora','Żuraw','Masłowski','Waśko','Długokęcki','Stenka','Dragon','Bałazy','Ciepliński','Śpiewak','Kisielewicz','Skolimowski','Buła','Wyrzykowski','Krawiec','Bonk','Chęć','Hoppe','Środa','Bigus','Łazarz','Wiśniowski','Kośla','Konik','Malicki','Rudzki','Dzido','Dubaj','Gdula','Ociepa','Ciba','Mikulski','Krzysztoń','Kępa','Kuźmicz','Antosiak','Siciński','Bartoszewicz','Lalik','Bekier','Reczek','Mikołajczuk','Wójcik','Budka','Cedro','Stawarz','Simiński','Królik','Podstawka','Sielski','Barczewski','Barczyński','Szablewski','Miler','Smuga','Kuliński','Cybulski','Dałek','Kudyba','Łyszczarz','Miętkiewicz','Bednarski','Borówka','Chrzanowski','Tabaka','Mikołajczyk','Puk','Belka','Szałkowski','Greń','Zawieja','Kowalewski','Pomykała','Gasiński','Drab','Drążek','Gralewski','Mendyk','Kupczyk','Jackowski','Świeca','Struski','Czechowicz','Szerszeń','Norek','Sztuka','Mrowiec','Pecyna','Jagodziński','Harasim','Węgrzyn','Sroczyński','Bartosiak','Pietrzak','Żurawski','Bartos','Krasowski','Bąk','Kryś','Chmielowiec','Gruchot','Kubik','Iwanek','Chodkowski','Abram','Misiak','Gądek','Nagórski','Jałowiecki','Głowacki','Gałuszka','Radzikowski','Woźnica','Podbielski','Sztandera','Skarbek','Piskorski','Gajewski','Barcik','Pikul','Kwoka','Waliczek','Frątczak','Połomski','Ulanowski','Nowosielski','Bober','Rudek','Gębka','Sibiński','Dziewięcki','Kochan','Derlatka','Basta','Rożek','Ukleja','Rutkiewicz','Rogulski','Stawski','Rowiński','Łubiński','Naskręt','Fijał','Nowakowski','Antoniak','Lasoń','Michalewski','Jaśkowski','Jaworski','Chmielarz','Pikuła','Czupryniak','Jastrząb','Tarka','Kozera','Bakalarski','Niedzwiecki','Marcol','Rydzewski','Zienkiewicz','Sroga','Urbaś','Rogala','Maliszewski','Sobczuk','Troszczyński','Wijas','Marcinkiewicz','Drzyzga','Kurkowski','Florkowski','Klukowski','Bloch','Szweda','Kędra','Golec','Kosiński','Sobiecki','Fąfara','Janiczek','Strózik','Woźniakowski','Antczak','Łukaszek','Baranek','Radzik','Gawenda','Klich','Krasnodębski','Bodzioch','Masiak','Kantorski','Kołacki','Wilamowski','Struzik','Pacek','Tusiński','Woźniczka','Kluczek','Durda','Żelazna','Lisiak','Markuszewski','Matuszak','Celmer','Kałużny','Lasek','Drożdż','Żbikowski','Piwoński','Firlej','Brych','Gapiński','Czerniak','Krzak','Siwicki','Ptasznik','Ficek','Radosz','Sokal','Dawidowicz','Kluk','Błachut','Kaniecki','Wawrzyński','Sordyl','Pędzich','Szczeciński','Zybała','Domagała','Klimaszewski','Smyczek','Durczak','Semeniuk','Grzegorzek','Czapski','Skowronek','Paradowski','Piskorek','Bugaj','Czapiewski','Szeremeta','Wojtysiak','Chrostek','Sobala','Wrzesiński','Ruszczyk','Królikowski','Ogiński','Dworak','Wołowiec','Stachera','Ceglarek','Augustyniak','Chełmiński','Grzelak','Mikos','Gumiński','Baca','Wójcikowski','Tomasiak','Ziemiński','Koziński','Wasiak','Sapiński','Dawid','Wołowicz','Prałat','Rosół','Czupryński','Krysa','Danilczuk','Madaj','Pyka','Kruczek','Grzywna','Kwaśnik','Frąckowiak','Jania','Klocek','Pytlak','Matejko','Żyłka','Nieć','Świerk','Musik','Więch','Filipek','Krawczak','Stanisz','Paszko','Chamera','Galas','Molęda','Matuszewski','Twardowski','Nieckarz','Baraniak','Cudak','Kijak','Dzięgiel','Ożga','Kluski','Kowalkowski','Młodzianowski','Pabian','Majer','Stepnowski','Płusa','Bartoń','Szewc','Gąsiorowski','Polowczyk','Drążkiewicz','Piwowarski','Dziekan','Banaś','Kurzak','Cyran','Pietruczuk','Mikuła','Sztorc','Rydel','Wereszczyński','Mizera','Sówka','Sobkowicz','Gospodarczyk','Radzki','Kulka','Choiński','Sujka','Rudnik','Kubiak','Szarzyński','Jaskulski','Wojdat','Wojtkiewicz','Minda','Kostrzewski','Podolak','Franczak','Olechno','Staszczyk','Polok','Strzelczyk','Hankus','Landowski','Fiut','Berent','Miszczuk','Wolna','Roszyk','Głuszek','Wolak','Jakubik','Chojnowski','Jakubowski','Bednarczuk','Korba','Ochocki','Romanik','Poprawa','Kachel','Białobrzeski','Koźmiński','Gogolewski','Jaśkowiak','Krasuski','Chuda','Kamionka','Kacprzak','Wierzbiński','Dworakowski','Chrobok','Lech','Chmurzyński','Czaplewski','Polek','Denisiuk','Mazgaj','Górczak','Sieroń','Janikowski','Chodorowski','Bielicki','Olszówka','Grenda','Rutecki');
	firstNames :=tabstr('Ada','Adalbert','Adam','Adela','Adelajda','Adrian','Aga','Agata','Agnieszka','Albert','Alberta','Aldona','Aleksander','Aleksandra','Alfred','Alicja','Alina','Amadeusz','Ambroży','Amelia','Anastazja','Anastazy','Anatol','Andrzej','Aneta','Angelika','Angelina','Aniela','Anita','Anna','Antoni','Antonina','Anzelm','Apolinary','Apollo','Apolonia','Apoloniusz','Ariadna','Arkadiusz','Arkady','Arlena','Arleta','Arletta','Arnold','Arnolf','August','Augustyna','Aurela','Aurelia','Aurelian','Aureliusz','Balbina','Baltazar','Barbara','Bartłomiej','Bartosz','Bazyli','Beata','Benedykt','Benedykta','Beniamin','Bernadeta','Bernard','Bernardeta','Bernardyn','Bernardyna','Błażej','Bogdan','Bogdana','Bogna','Bogumił','Bogumiła','Bogusław','Bogusława','Bohdan','Bolesław','Bonawentura','Bożena','Bronisław','Broniszław','Bronisława','Brunon','Brygida','Cecyl','Cecylia','Celestyn','Celestyna','Celina','Cezary','Cyprian','Cyryl','Dalia','Damian','Daniel','Daniela','Danuta','Daria','Dariusz','Dawid','Diana','Dianna','Dobrawa','Dominik','Dominika','Donata','Dorian','Dorota','Dymitr','Edmund','Edward','Edwin','Edyta','Egon','Eleonora','Eliasz','Eligiusz','Eliza','Elwira','Elżbieta','Emanuel','Emanuela','Emil','Emilia','Emilian','Emiliana','Ernest','Ernestyna','Erwin','Erwina','Eryk','Eryka','Eugenia','Eugeniusz','Eulalia','Eustachy','Ewelina','Fabian','Faustyn','Faustyna','Felicja','Felicjan','Felicyta','Feliks','Ferdynand','Filip','Franciszek','Franciszek','Salezy','Franciszka','Fryderyk','Fryderyka','Gabriel','Gabriela','Gaweł','Genowefa','Gerard','Gerarda','Gerhard','Gertruda','Gerwazy','Godfryd','Gracja','Gracjan','Grażyna','Greta','Grzegorz','Gustaw','Gustawa','Gwidon','Halina','Hanna','Helena','Henryk','Henryka','Herbert','Hieronim','Hilary','Hipolit','Honorata','Hubert','Ida','Idalia','Idzi','Iga','Ignacy','Igor','Ildefons','Ilona','Inga','Ingeborga','Irena','Ireneusz','Irma','Irmina','Irwin','Ismena','Iwo','Iwona','Izabela','Izolda','Izyda','Izydor','Jacek','Jadwiga','Jagoda','Jakub','Jan','Janina','January','Janusz','Jarema','Jarogniew','Jaromir','Jarosław','Jarosława','Jeremi','Jeremiasz','Jerzy','Jędrzej','Joachim','Joanna','Jolanta','Jonasz','Jonatan','Jowita','Józef','Józefa','Józefina','Judyta','Julia','Julian','Julianna','Julita','Juliusz','Justyn','Justyna','Kacper','Kaja','Kajetan','Kalina','Kamil','Kamila','Karina','Karol','Karolina','Kacper','Kasper','Katarzyna','Kazimiera','Kazimierz','Kinga','Klara','Klarysa','Klaudia','Klaudiusz','Klaudyna','Klemens','Klementyn','Klementyna','Kleopatra','Klotylda','Konrad','Konrada','Konstancja','Konstanty','Konstantyn','Kordelia','Kordian','Kordula','Kornel','Kornelia','Kryspin','Krystian','Krystyn','Krystyna','Krzysztof','Ksenia','Kunegunda','Laura','Laurenty','Laurentyn','Laurentyna','Lech','Lechosław','Lechosława','Leokadia','Leon','Leonard','Leonarda','Leonia','Leopold','Leopoldyna','Lesław','Lesława','Leszek','Lidia','Ligia','Lilian','Liliana','Lilianna','Lilla','Liwia','Liwiusz','Liza','Lolita','Longin','Loretta','Luba','Lubomir','Lubomira','Lucja','Lucjan','Lucjusz','Lucyna','Ludmiła','Ludomił','Ludomir','Ludosław','Ludwik','Ludwika','Ludwina','Luiza','Lukrecja','Lutosław','Łucja','Łucjan','Łukasz','Maciej','Madlena','Magda','Magdalena','Makary','Maksym','Maksymilian','Malina','Malwin','Malwina','Małgorzata','Manfred','Manfreda','Manuela','Marcel','Marcela','Marceli','Marcelina','Marcin','Marcjan','Marcjanna','Marcjusz','Marek','Margareta','Maria','MariaMagdalena','Marian','Marianna','Marietta','Marina','Mariola','Mariusz','Marlena','Marta','Martyna','Maryla','Maryna','Marzanna','Marzena','Mateusz','Matylda','Maurycy','Melania','Melchior','Metody','Michalina','Michał','Mieczysław','Mieczysława','Mieszko','Mikołaj','Milena','Miła','Miłosz','Miłowan','Miłowit','Mira','Mirabella','Mirella','Miron','Mirosław','Mirosława','Modest','Monika','Nadia','Nadzieja','Napoleon','Narcyz','Narcyza','Nastazja','Natalia','Natasza','Nikita','Nikodem','Nina','Nora','Norbert','Norberta','Norma','Norman','Oda','Odila','Odon','Ofelia','Oksana','Oktawia','Oktawian','Olaf','Oleg','Olga','Olgierd','Olimpia','Oliwia','Oliwier','Onufry','Orfeusz','Oskar','Otto','Otylia','Pankracy','Parys','Patrycja','Patrycy','Patryk','Paula','Paulina','Paweł','Pelagia','Petronela','Petronia','Petroniusz','Piotr','Pola','Polikarp','Protazy','Przemysław','Radomił','Radomiła','Radomir','Radosław','Radosława','Radzimir','Rafael','Rafaela','Rafał','Rajmund','Rajmunda','Rajnold','Rebeka','Regina','Remigiusz','Rena','Renata','Robert','Roberta','Roch','Roderyk','Rodryg','Rodryk','Roger','Roksana','Roland','Roma','Roman','Romana','Romeo','Romuald','Rozalia','Rozanna','Róża','Rudolf','Rudolfa','Rudolfina','Rufin','Rupert','Ryszard','Ryszarda','Sabina','Salomea','Salomon','Samuel','Samuela','Sandra','Sara','Sawa','Sebastian','Serafin','Sergiusz','Sewer','Seweryn','Seweryna','Sędzisław','Sędziwoj','Siemowit','Sława','Sławomir','Sławomira','Sławosz','Sobiesław','Sobiesława','Sofia','Sonia','Stanisław','Stanisława','Stefan','Stefania','Sulimiera','Sulimierz','Sulimir','Sydonia','Sykstus','Sylwan','Sylwana','Sylwester','Sylwia','Sylwiusz','Symeon','Szczepan','Szczęsna','Szczęsny','Szymon','Ścibor','Świętopełk','Tadeusz','Tamara','Tatiana','Tekla','Telimena','Teodor','Teodora','Teodozja','Teodozjusz','Teofil','Teofila','Teresa','Tobiasz','Toma','Tomasz','Tristan','Trojan','Tycjan','Tymon','Tymoteusz','Tytus','Unisław','Ursyn','Urszula','Violetta','Wacław','Wacława','Waldemar','Walenty','Walentyna','Waleria','Walerian','Waleriana','Walery','Walter','Wanda','Wasyl','Wawrzyniec','Wera','Werner','Weronika','Wieńczysła','Wiesław','Wiesława','Wiktor','Wiktoria','Wilhelm','Wilhelmina','Wilma','Wincenta','Wincenty','Wińczysła','Wiola','Wioletta','Wirgiliusz','Wirginia','Wirginiusz','Wisław','Wisława','Wit','Witalis','Witold','Witolda','Witołd','Witomir','Wiwanna','Władysława','Władysław','Włodzimierz','Włodzimir','Wodzisław','Wojciech','Wojciecha','Zachariasz','Zbigniew','Zbysław','Zbyszko','Zdobysław','Zdzisław','Zdzisława','Zenobia','Zenobiusz','Zenon','Zenona','Ziemowit','Zofia','Zula','Zuzanna','Zygfryd','Zygmunt','Zyta','Żaklina','Żaneta','Żanna','Żelisław','Żytomir');
    streets := tabstr('11 Listopada','15 Sierpnia','17 Stycznia','1 Maja','1 Praskiego Pułku','1 Praskiego Pułku (Wesoła)','1 Sierpnia','20 Dywizji Piechoty Wojska Polskiego','21 Pułku Piechoty Dzieci Warszawy','27 Grudnia','29 Listopada','2 Armii Wojska Polskiego','36 Pułku Piechoty Legii Akademickiej','3 Maja','6 Sierpnia','Abecadło','Achillesa','Adama Asnyka','Adama Branickiego','Adama Ciołkosza','Adama Idźkowskiego','Adama Jarzębskiego','Adama Mickiewicza','Adampolska','Admiralska','Adolfa Dygasińskiego','Afrodyty','Afrykańska','Agatowa','Agawy','Agnieszki','Agrarna','Agrestowa','Agrykola','Akacjowa','Akademicka','Akantu','Akcent','Akermańska','Aksamitna','Aktorska','Akurat','Akustyczna','Akwarelowa','Alabastrowa','Albatrosów','Alberta Einsteina','Albina Jakiela','aleja Dzieci Polskich','aleja Hrabska','aleja Jana Chrystiana Szucha','aleja Jana Pawła II','aleja Kazimierza Kumanieckiego','aleja Krakowska','aleja Legionów','Aleja Marszałka Józefa Piłsudskiego','aleja Marszałka Józefa Piłsudskiego (Wesoła)','aleja Niepodległości','aleja Solidarności','Aleja Wilanowska','aleja Wyzwolenia','aleja Zieleniecka','Aleje Jerozolimskie','Aleje Ujazdowskie','Aleksandra Bardiniego','Aleksandra Dyżewskiego','Aleksandra Fleminga','Aleksandra Fredry','Aleksandra Gajkowicza','Aleksandra Gierymskiego','Aleksandra Janowskiego','Aleksandra Kamińskiego','Aleksandra Kostki-Napierskiego','Aleksandra Kotsisa','Aleksandra Kowalskiego','Aleksandra Kraushara','Aleksandra Krywulta','Aleksandrowska','Algierska','Alojzego Felińskiego','Alpejska','Alternatywy','Altowa','Aluzyjna','Alzacka','Amarantowa','Ambaras','Amelińska','Ametystowa','Analityczna','Ananasowa','Anastazego Kowalczyka','Andersa','Andromedy','Andrutowa','Andrychowska','Andrzeja Frycza-Modrzewskiego','Andrzeja Krzyckiego','Andrzejowska','Andyjska','Anecińska','Angorska','Anieli Krzywoń','Anilinowa','Animuszu','Annopol','Anny Jagiellonki','Antenowa','Antka Rozpylacza','Antoniego Bolesława Dobrowolskiego','Antoniego Brodowskiego','Antoniego Corazziego','Antoniego Czechowa','Antoniego Dobiszewskiego','Antoniego Fontany','Antoniego Grabowskiego','Antoniego Kacpury','Antoniego Kocjana','Antoniewska','Antyczna','Antygony','Anyżkowa','Apartamentowa','Apenińska','Aplikancka','Apollina','Apteczna','Arabska','Arachidowa','Arbuzowa','Archimedesa','Architektów','Archiwalna','Argentyńska','Arkadowa','Arkadyjska','Arkony','Arktyczna','Arkuszowa','Armanda Calinescu','Armatnia','Armii Krajowej','Armii Ludowej','Arniki','Aroniowa','Arrasowa','Arsenalska','Artemidy','Artura Grottgera','Artyleryjska','Artystów','Artystyczna','Asfaltowa','Aspekt','Astronautów','Astronomów','Astrów','Astry','Ateńska','Atlasowa','Atutowa','Augusta Cieszkowskiego','Augustówka','Augustyna Kordeckiego','Awionetki RWD','Azaliowa','Babicka','Babiego Lata','Babie Lato','Babimojska','Babinicza','Baborowska','Baboszewska','Bachmacka','Bachusa','Badowska','Badylarska','Bagatela','Bagażowa','Bagno','Bajeczna','Bajkowa','Bajońska','Bakalarska','Bakaliowa','Balaton','Balbinki','Baletowa','Balicka','Balkonowa','Balladyny','Balonowa','Baltazara','Bałtycka','Bambusowa','Bananowa','Banderii','Bandoski','Banioska','Bankowa','Baonu Zośka','Baranowska','Barcelońska','Barcicka','Barkocińska','Barokowa','Barska','Barszczewska','Bartłomieja','Bartnicza','Bartoka','Bartosza Głowackiego','Bartoszycka','Bartycka','Barwinkowa','Barwna','Barwnicza','Baryczków','Baśniowa','Batalionów Chłopskich','Batalionu "Parasol"','Batalionu AK "Bałtyk"','Batalionu AK "Karpaty"','Batalionu AK "Olza"','Batalionu AK "Pięść"','Batalionu AK "Ryś"','Batalionu Miotła','Batalionu Oaza','Batalionu Platerówek','Batumi','Batuty','Batystowa','Bawełniana','Bażancia','Bazyliańska','Beczkowa','Bednarska','Będzińska','Begonii','Bekasów','Bełchatowska','Bełdan','Belgijska','Belgradzka','Bellony','Bełska','Belwederska','Bełżecka','Benedykta','Benedykta Dybowskiego','Benedykta Hertza','Berberysowa','Berestecka','Berezyńska','Berka Joselewicza','Bernardyńska','Berneńska','Bertolta Brechta','Beskidzka','Biała','Białej Wody','Białoborska','Białobrzeska','Białogońska','Białołęcka','Białoskórnicza','Białostocka','Białowiejska','Białowieska','Białozora','Biały Kamień','Biechowska','Biedronki','Bielańska','Bielawska','Bielska','Bielszowicka','Bieniewicka','Biernacka','Biernata z Lublina','Biesiadna','Bieszczadzka','Bieżanowska','Bieżuńska','Biłgorajska','Biruty','Birżańska','Biskupia','Bitna','Bitwy Grochowskiej','Bitwy pod Lenino','Bitwy pod Rokitną','Bitwy Warszawskiej 1920 r.','Biwakowa','Blacharska','Blaszana','Bławatków','Błażeja','Błędowska','Błękitna','Bliska','Blokowa','Błonie','Błońska','Błotna','Bluszczańska','Bluszczowa','Bobrowa','Bobrowiecka','Bocheńska','Bociania','Boczańska','Boczna','Boczniaków','Bodzanty','Bogatki','Bogatyńska','Boglarczyków','Bogoriów','Bogucicka','Bogumińska','Bogunki','Boguszewska','Bohaterów','Bohaterów Getta','Bohdziewicza','Bohuna','Bokserska','Bolecha','Boleść','Bolesława Chrobrego','Bolesława Gidzińskiego','Bolesława Krzywoustego','Bolesława Limanowskiego','Bolesława Prusa','Bolesława Prusa (Wesoła)','Bolesława Śmiałego','Bolesławicka','Bolimowska','Bolkowska','Bombardierów','Bonifraterska','Bonisławska','Borecka','Boremlowska','Borków','Borkowska','Borowa','Borowej Góry','Borowiecka','Borowika','Borówkowa','Borsucza','Boruty','Boryny','Borysławska','Boryszewska','Borzęcińska','Borzymowska','Bosmańska','Botaniczna','Bożka Arki','Braci Wagów','Bracka','Bracławska','Bramka','Braniewska','Brata Alberta','Braterstwa Broni','Bratka','Bratnia','Brązownicza','Brazylijska','Brochowska','Brodnicka','Brodzik','Bronisława Czecha','Bronisława Dobrzańskiego','Bronisława Gembarzewskiego','Broniwoja','Bronowska','Browarna','Brukselska','Brunona Kicińskiego','Bruszewska','Bruzdowa','Brwinowska','Brygady Pościgowej','Brygadzistów','Brylantowa','Brylowska','Brzegowa','Brzeska','Brzezińska','Brzeziny','Brzoskwiniowa','Brzostowska','Brzozowa','Brzozowy Zagajnik','Buchalteryjna','Budki Szczęśliwickie','Budnicza','Budowlana','Budrysów','Budy','Bugaj','Bukietowa','Bukowa','Bukowiecka','Bukowińska','Bukszpanowa','Buławy','Bułgarska','Bulwarowa','Buńczuk','Buraczana','Burakowska','Burgaska','Burleska','Burmistrzowska','Bursztynowa','Burzliwa','Buska','Busolowa','Buszycka','Bychowska','Byczyńska','Bylicowa','Bysławska','Bystra','Bystrzycka','Byszewska','Bytomska','Bzowa','Calineczki','Calowa','Canaletta','Capri','Carla Goldoniego','Cedrowa','Cedzyńska','Cegielniana','Ceglana','Cegłowska','Celestynowska','Celna','Celofanowa','Celtów','Celulozy','Cementowa','Centralna','Centurii','Ceramiczna','Cesarskiej Korony','Chabrów','Chabrowa','Chałupnicza','Chęcińska','Chełchowska','Chełmska','Chełmżyńska','Chemiczna','Chińskiej Róży','Chlebowa','Chlewińska','Chłodna','Chłodnicza','Chlubna','Chmielna','Chmurna','Chochołowska','Chocimska','Chodakowska','Chodecka','Chodzieska','Choinkowa','Chojnowska','Chorągwi Pancernej','Chóralna','Chorzelska','Chorzowska','Chotomowska','Christa Botewa','Chroszczewska','Chryzantemy','Chylicka','Chylońska','Chyrowska','Ciasna','Cicha','Cichej Wody','Cichociemnych','Ciechanowska','Ciechocińska','Ciekawa','Ciemna','Cienista','Ciepielowska','Ciepła','Cieplarniana','Cieplicka','Cierlicka','Ciesielska','Cieślewskich','Cieszyńska','Cietrzewia','Cisowa','Ciszewska','Ciupagi','Ciżemki','Cmentarna','Codzienna','Cokołowa','Cudna','Cudne Manowce','Cudnowska','Cukrownicza','Cybernetyki','Cyganeczki','Cygańska','Cyklamenów','Cyklamenowa','Cylichowska','Cymbalistów','Cynamonowa','Cynowa','Cypriana Godebskiego','Cypriana Norwida','Cypryjska','Cyprysowa','Cyraneczki','Cyrhli','Cyrklowa','Cyrkonii','Cyrulików','Cytadeli','Cytrynowa','Czajki','Czapelska','Czapli','Czapnicza','Czardasza','Czarna Droga','Czarnocińska','Czarnołęcka','Czarnoleska','Czarnomorska','Czarnuszki','Czarodzieja','Cząstkowska','Czatów','Czechowicka','Czekanowska','Czekoladowa','Czeladnicza','Czempińska','Czeremchowa','Czereśniowa','Czerniakowska','Czerniowiecka','Czerska','Czerwińska','Czerwona Droga','Czerwonego Krzyża','Czerwonych Beretów','Czerwonych Maków','Czerwonych Wierchów','Czeska','Czesława Kłosia','Cześnika','Częstochowska','Człuchowska','Czółenkowa','Czołgistów','Czołowa','Czorsztyńska','Czterech Wiatrów','Czubatki','Czujna','Czumy','Czwartaków','Czynszowa','Czysta','Czytelnicza','Czyżewska','Czyżyka','Dąbrowiecka','Dąbrowszczaków','Dąbrowy','Daglezji','Daków','Daktylowa','Dalanowska','Daleka','Daleszycka','Dalibora','Daliowa','Daniewice','Daniłowiczowska','Daniszewska','Dankowicka','Dantego','Danusi','Darłowska','Darniowa','Daszowska','Dawidowska','Dawna','Dębicka','Dębinki','Dęblińska','Dębowa','Dęby','Dedala','Dekarska','Delfina','Denarowa','Deotymy','Deptak','Derby','Dereniowa','Derkaczy','Derwida','Deseniowa','Deszczowa','Dewajtis','Diamentowa','Dionizosa','Długa','Długomiła','Długopolska','Długorzeczna','Dmuchawcowa','Dobka z Oleśnicy','Dobosza','Dobra','Dobrodzieja','Dobrogniewa','Dobrowoja','Dojazdowa','Dokerów','Dolina Służewiecka','Dolna','Dolnośląska','Dolomitowa','Dołowa','Domaniewska','Dominikańska','Dominiki','Domowa','Don Kichota','Dorodna','Dorohuska','Dorotowska','Doroty Kłuszyńskiej','Dorycka','Dostatnia','Dostępna','Dowcip','Dowódców','Dożynkowa','Do Fortu','Dragonów','Drapińska','Drawska','Drewniana','Drewnicka','Drezdeńska','Drobiazg','Droga Golfowa','Droga Krajowa 8','Droga Wojewódzka 637','Drogistów','Drogomilska','Drogowa','Drohicka','Drohobycka','Drozdowa','Drożdżowa','Druciana','Drukarzy','Drumli','Drużynowa','Drwali','Drzemlika','Drzeworytników','Dubieńska','Duchnicka','Dudziarska','Dukatowa','Dukielska','Dulczyńska','Dumki','Dunajecka','Duninów','Dusznicka','Dwóch Mieczy','Dworcowa','Dworkowa','Dworska','Dwusieczna','Dychowska','Dylewska','Dyliżansowa','Dymińska','Dymna','Dynamiczna','Dynarska','Dynasy','Dyngus','Dynowska','Dywizjonu 303','Dywizjonu AK "Jeleń"','Działdowska','Działkowa','Działowa','Działyńczyków','Dziatwy','Dzidka Warszawiaka','Dziecięca','Dzięcieliny','Dzięcioła','Dzieci Warszawy','Dzięgielowa','Dziekania','Dziekanowska','Dzielna','Dzielnicowa','Dziennikarska','Dzierzby','Dzierzgońska','Dzierżoniowska','Dziewanny','Dziewanowska','Dziewiarska','Dziewierza','Dziewosłęby','Dzika','Dzikiej Kaczki','Dzikiej Róży','Dziupli','Dziwożony','Dźwiękowa','Dźwigowa','Dźwińska','Dzwonkowa','Dzwonnicza','Ebro','Echa Leśne','Edwarda Abramowskiego','Edwarda Dembowskiego','Edwarda Fondamińskiego','Edwarda Gibalskiego','Edwarda Jelinka','Edwarda Szymańskiego','Egejska','Egipska','Ekologiczna','Ekspresowa','Elbląska','Elegancka','Elegijna','Elekcyjna','Elektoralna','Elektronowa','Elektry','Elektryczna','Elizy Orzeszkowej','Elsterska','Elżbiety Drużbackiej','Emaliowa','Emiliana Konopczyńskiego','Emilii Gierczak','Emilii Plater','Encyklopedyczna','Epopei','Erazma Ciołka','Erazma z Zakroczymia','Eryka Dahlberga','Esej','Eskimoska','Eskulapów','Esperanto','Estońska','Estrady','Etiudy Rewolucyjnej','Eugeniusza Bodo','Eugeniusza Horbaczewskiego','Eugeniusza Kwiatkowskiego','Europejska','Ewy','Ezopa','Fabiańska','Fabryczna','Fajansowa','Falęcka','Falenicka','Falentyńska','Falkowska','Familijna','Fanfarowa','Fantazyjna','Faraona','Farbiarska','Farysa','Fasolowa','Fausta','Faustyna Czerwijowskiego','Fawory','Figara','Figiel','Figowa','Filarecka','Filipinki','Filipiny Płaskowickiej','Filmowa','Filomatów','Filona','Filtrowa','Finałowa','Finlandzka','Fińska','Fioletowa','Fiołków','Firletki','Fizyków','Fizylierów','Flagowa','Flamenco','Fletniowa','Flisaków','Floksów','Floriana','Floriańska','Flory','Foksal','Foliałowa','Folwarczna','Forsycji','Forteczna','Fortel','Fortowa','Fortuny','Fort Wola','Fosa','Frachtowa','Franciszkańska','Franciszka Achera','Franciszka Bartoszka','Franciszka Groëra','Franciszka Ilskiego','Franciszka Karpińskiego','Franciszka Kawy','Franciszka Kleeberga','Franciszka Klimczaka','Franciszka Kniaźnina','Franciszka Kostrzewskiego','Franciszka Ksawerego Dmochowskiego','Franciszka Salezego Jezierskiego','Francuska','Frascati','Fraszki','Fregaty','Freta','Frezji','Fromborska','Frontowa','Fryderyka Chopina','Frygijska','Frysztacka','Fukierów','Fuksji','Fundamentowa','Furmańska','Gąbińska','Gabriela','Gabriela Boduena','Gabrieli Zapolskiej','Gaik','Gajdy','Gajowa','Galaktyki','Galileusza','Galla Anonima','Galopu','Garażowa','Garbarska','Gardenii','Garłaczy','Garncarska','Garwolińska','Gąsek','Gąsienicowa','Gąsocińska','Gawędziarzy','Gawota','Gazowa','Gdańska','Gdecka','Gdyńska','Gębicka','Gedymina','gen. Meriana C. Coopera','gen. Mikołaja Bołtucia','Generała Władysława Andersa','Genewska','Geodetów','Geodezyjna','Geograficzna','Geologiczna','Geometryczna','Geranii','Gerberowa','Gerwazego','Gęślarska','Gęsta','Gibraltarska','Giełdowa','Gierdawska','Giermków','Giewont','Gilarska','Gimnastyczna','Gimnazjalna','Gizów','Gladioli','Gładka','Głębocka','Głęboka','Glebowa','Glicynii','Gliwicka','Globusowa','Głogowa','Głogowska','Główna','Głubczycka','Głucha','Głuszca','Głuszycka','Gniazdowska','Gniewkowska','Gnieźnieńska','Gocławska','Goczałkowicka','Godlewska','Godowska','Godziszowska','Gogolińska','Goławicka','Gołdapska','Gołębia','Golędzinowska','Goleszowska','Golfowa','Gołkowska','Gołuchowska','Gontarska','Goplańska','Gorajska','Góralska','Goraszewska','Górczewska','Gorlicka','Górna','Górna Droga','Górnośląska','Górska','Goryczkowa','Gorzelnicza','Gorzykowska','Gościeradowska','Gościniec','Gościnna','Gospodarcza','Gostyńska','Gotarda','Gottlieba Daimlera','Gotycka','Goworka','Goworowska','Gozdawitów','Goździków','Grabalówki','Grabowska','Grafitowa','Grajewska','Graniczna','Granitowa','Granowska','Grawerska','Grażyny','Grażyny Bacewiczówny','Grębałowska','Grecka','Gremplarska','Grenadierów','Grenady','Grobelska','Grocholicka','Grochowska','Grodkowska','Grodzieńska','Grodzka','Grójecka','Gronowa','Groszowicka','Groteski','Grotowska','Gruchacza','Gruntowa','Grupy AK "Kampinos"','Grupy AK "Północ"','Gruszy','Gruzińska','Gryczana','Gryfitów','Grzegorza Fitelberga','Grzybowa','Grzybowska','Grzymalitów','Grzywaczy','Gubinowska','Guliwera','Gułowska','Guńki','Gustawa','Gustawa Daniłowskiego','Guźca','Gwardii','Gwarków','Gwiaździsta','Gwintowa','Gżegżółki','Haczowska','Hafciarska','Hajduczka','Hajnowska','Hajoty','Haliny Krahelskiej','Halki','Halna','Handlowa','Hanki Czaki','Hansa Christiana Andersena','Harcerska','Harendy','Harfowa','Harmonistów','Harnasie','Haubicy','Hawajska','Hebanowa','Hejnałowa','Hektarowa','Heleny Junkiewicz','Heleny Kozłowskiej','Heliotropów','Heloizy','Henryka Arctowskiego','Henryka Barona','Henryka Brodatego','Henryka Dembińskiego','Henryka Jędrzejowskiego','Henryka Pobożnego','Henryka Probusa','Henryka Sienkiewicza','Henrykowska','Herakliusza Billewicza','Herbaciana','Herbowa','Hermanowska','Heroldów','Hery','Hetmańska','Hiacyntowa','Hieroglif','Himalajska','Hipolitowo','Hipoteczna','Hipotezy','Hodowlana','Holenderska');
    cities := tabstr('Radków','Siechnice','Sobótka','Stronie Śląskie','Strzegom','Strzelin','Syców','Szczawno Zdrój','Szczytna','Szklarska Poręba','Ścinawa','Środa Śląska','Świdnica','Świebodzice','Świeradów Zdrój','Świerzawa','Trzebnica','Twardogóra','Wałbrzych','Wąsosz','Węgliniec','Wiązów','Wleń','Wojcieszów','Wołów','Wrocław','Zawidów','Ząbkowice Śląskie','Zgorzelec','Ziębice','Złotoryja','Złoty Stok','Żarów','Żmigród','Janikowo','Janowiec Wielkopolski','Kamień Krajeński','Kcynia','Koronowo','Kowal','Kowalewo Pomorskie','Kruszwica','Lipno','Lubień Kujawski','Lubraniec','Łabiszyn','Łasin','Mogilno','Mrocza','Nakło nad Notecią','Nieszawa','Nowe','Pakość','Piotrków Kujawski','Radziejów','Radzyń Chełmiński','Rypin','Sępólno Krajeńskie','Skępe','Solec Kujawski','Strzelno','Szubin','Świecie','Toruń','Tuchola','Wąbrzeźno','Więcbork','Włocławek','Żnin','Józefów','Kazimierz Dolny','Kock','Krasnobród','Krasnystaw','Kraśnik','Lubartów','Lublin','Łęczna','Łuków','Międzyrzec Podlaski','Nałęczów','Opole Lubelskie','Ostrów Lubelski','Parczew','Piaski','Poniatowa','Puławy','Radzyń Podlaski','Rejowiec Fabryczny','Ryki','Stoczek Łukowski','Szczebrzeszyn','Świdnik','Tarnogród','Terespol','Tomaszów Lubelski','Włodawa','Zamość','Zwierzyniec','Babimost','Bytom Odrzański','Cybinka','Czerwieńsk','Dobiegniew','Drezdenko','Gorzów Wielkopolski','Gozdnica','Gubin','Iłowa','Jasień','Kargowa','Kostrzyn','Kożuchów','Krosno Odrzańskie','Lubniewice','Lubsko','Łęknica','Małomice','Międzyrzecz','Nowa Sól','Nowe Miasteczko','Nowogród Bobrzański','Ośno Lubuskie','Rzepin','Skwierzyna','Sława','Słubice','Strzelce Krajeńskie','Sulechów','Sulęcin','Szlichtyngowa','Szprotawa','Świebodzin','Torzym','Trzciel','Witnica','Wschowa','Zbąszynek','Zielona Góra','Żagań','Żary','Aleksandrów Łódzki','Bełchatów','Biała Rawska','Błaszki','Brzeziny','Drzewica','Działoszyn','Głowno','Kamieńsk','Koluszki','Konstantynów Łódzki','Krośniewice','Kutno','Łask','Łęczyca','Łowicz','Łódź','Opoczno','Ozorków','Pabianice','Pajęczno','Piotrków Trybunalski','Poddębice','Przedbórz','Radomsko','Rawa Mazowiecka','Sieradz','Skierniewice','Stryków','Sulejów','Szadek','Tomaszów Mazowiecki','Tuszyn','Uniejów','Warta','Wieluń','Wieruszów','Zduńska Wola','Zelów','Zgierz','Złoczew','Żychlin','Alwernia','Andrychów','Biecz','Bochnia','Brzesko','Brzeszcze','Bukowno','Chełmek','Chrzanów','Ciężkowice','Czchów','Dąbrowa Tarnowska','Dobczyce','Gorlice','Grybów','Jordanów','Kalwaria Zebrzydowska','Kęty','Kraków','Krynica','Krzeszowice','Libiąż','Limanowa','Maków Podhalański','Miechów','Mszana Dolna','Muszyna','Myślenice','Niepołomice','Nowy Sącz','Nowy Targ','Nowy Wiśnicz','Olkusz','Oświęcim','Piwniczna Zdrój','Proszowice','Rabka','Skała','Skawina','Sławków','Słomniki','Stary Sącz','Sucha Beskidzka','Sułkowice','Szczawnica','Świątniki Górne','Tarnów','Trzebinia','Tuchów','Wadowice','Wieliczka','Wolbrom','Zakopane','Zator','Żabno','Białobrzegi','Bieżuń','Błonie','Brok','Brwinów','Chorzele','Ciechanów','Drobin','Garwolin','Gąbin','Glinojeck','Gostynin','Góra Kalwaria','Grodzisk Mazowiecki','Grójec','Iłża','Józefów','Kałuszyn','Karczew','Kobyłka','Konstancin-Jeziorna','Kosów Lacki','Kozienice','Legionowo','Lipsko','Łaskarzew','Łochów','Łomianki','Łosice','Maków Mazowiecki','Marki','Milanówek','Mińsk Mazowiecki','Mława','Mogielnica','Mordy','Mszczonów','Myszyniec','Nasielsk','Nowe Miasto nad Pilicą','Nowy Dwór Mazowiecki','Ostrołęka','Ostrów Mazowiecka','Otwock','Ożarów Mazowiecki','Piaseczno','Piastów','Pilawa','Pionki','Płock','Płońsk','Podkowa Leśna','Pruszków','Przasnysz','Przysucha','Pułtusk','Raciąż','Radom','Radzymin','Różan','Serock','Siedlce','Sierpc','Skaryszew','Sochaczew','Sokołów Podlaski','Sulejówek','Szydłowiec','Tłuszcz','Warka','Warszawa','Wesoła','Węgrów','Wołomin','Wyszków','Wyszogród','Wyśmierzyce','Zakroczym','Ząbki','Zielonka','Zwoleń','Żelechów','Żuromin','Żyrardów','Baborów','Biała','Brzeg','Byczyna','Dobrodzień','Głogówek','Głubczyce','Głuchołazy','Gogolin','Gorzów Śląski','Grodków','Kędzierzyn-Koźle','Kietrz','Kluczbork','Kolonowskie','Korfantów','Krapkowice','Leśnica','Lewin Brzeski','Namysłów','Niemodlin','Nysa','Olesno','Opole','Otmuchów','Ozimek','Paczków','Praszka','Prudnik','Strzelce Opolskie','Ujazd','Wołczyn','Zawadzkie','Zdzieszowice','Baranów Sandomierski','Błażowa','Brzozów','Cieszanów','Dębica','Dukla','Dynów','Głogów Małopolski','Iwonicz Zdrój','Jarosław','Jasło','Jedlicze','Kańczuga','Kolbuszowa','Krosno','Lesko','Leżajsk','Lubaczów','Łańcut','Mielec','Narol','Nisko','Nowa Dęba','Nowa Sarzyna','Oleszyce','Pilzno','Przemyśl','Przeworsk','Radomyśl Wielki','Radymno','Ropczyce','Rudnik nad Sanem','Rymanów','Rzeszów','Sanok','Sędziszów Małopolski','Sieniawa','Sokołów Małopolski','Stalowa Wola','Strzyżów','Tarnobrzeg','Tyczyn','Ulanów','Ustrzyki Dolne','Zagórz','Augustów','Białystok','Bielsk Podlaski','Brańsk','Choroszcz','Ciechanowiec','Czarna Białostocka','Brusy','Bytów','Chojnice','Czarna Woda','Czarne','Czersk','Człuchów','Debrzno','Dzierzgoń','Gdańsk','Gdynia','Gniew','Hel','Jastarnia','Kartuzy','Kościerzyna','Krynica Morska','Kwidzyn','Lębork','Łeba','Malbork','Miastko','Nowy Dwór Gdański','Nowy Staw','Pelplin','Prabuty','Pruszcz Gdański','Puck','Reda','Rumia','Skarszewy','Skórcz','Słupsk','Sopot','Starogard Gdański','Sztum','Tczew','Ustka','Wejherowo','Władysławowo','Żukowo','Lędziny','Lubliniec','Łaziska Górne','Łazy','Miasteczko Śląskie','Mikołów','Mysłowice','Myszków','Ogrodzieniec','Orzesze','Piekary Śląskie','Pilica','Poręba','Pszczyna','Pszów','Pyskowice','Racibórz','Radlin','Radzionków','Ruda Śląska','Rybnik','Rydułtowy','Siemianowice Śląskie','Siewierz','Skoczów','Sosnowiec','Sośnicowice','Strumień','Szczekociny','Szczyrk','Świętochłowice','Tarnowskie Góry','Toszek','Tychy','Ustroń','Wilamowice','Wisła','Wodzisław Śląski','Wojkowice','Woźniki','Zabrze','Zawiercie','Żarki','Żory','Żywiec','Bojanowo','Borek Wielkopolski','Buk','Chodzież','Czarnków','Czempiń','Czerniejewo','Dąbie','Dobra','Dolsk','Gniezno','Golina','Gołańcz','Gostyń','Grabów nad Prosną','Grodzisk Wielkopolski','Jarocin','Jastrowie','Jutrosin','Kalisz','Kępno','Kleczew','Kłecko','Kłodawa','Kobylin','Koło','Konin','Kostrzyn','Kościan','Koźmin Wielkopolski','Kórnik','Krajenka','Krobia','Krotoszyn','Krzywiń','Krzyż Wielkopolski','Książ Wielkopolski','Leszno','Luboń','Lwówek','Łobżenica','Margonin','Miejska Górka','Międzychód','Mikstat','Miłosław','Mosina','Murowana Goślina','Nekla','Nowe Skalmierzyce','Nowy Tomyśl','Oborniki','Obrzycko','Odolanów','Okonek','Opalenica','Osieczna','Ostroróg','Ostrów Wielkopolski','Ostrzeszów','Piła','Pleszew','Pniewy','Pobiedziska','Pogorzela','Poniec','Poznań','Przedecz','Puszczykowo','Pyzdry','Rakoniewice','Raszków','Rawicz','Rogoźno','Rychwał','Rydzyna','Sieraków','Skoki','Słupca','Sompolno','Stawiszyn','Stęszew','Sulmierzyce','Swarzędz','Szamocin','Szamotuły','Ślesin','Śmigiel','Śrem','Środa Wielkopolska','Trzcianka','Trzemeszno','Tuliszków','Turek','Ujście','Wągrowiec','Wieleń','Wielichowo','Witkowo','Wolsztyn','Wronki','Września','Wyrzysk','Wysoka','Zagórów','Zbąszyń','Zduny','Złotów','Żerków','Barczewo','Bartoszyce','Biała Piska','Biskupiec','Bisztynek','Braniewo','Dobre Miasto','Działdowo','Elbląg','Ełk','Frombork','Giżycko','Gołdap','Górowo Iławeckie','Iława','Jeziorany','Kętrzyn','Kisielice','Korsze','Lidzbark','Lidzbark Warmiński','Lubawa','Mikołajki','Miłakowo','Miłomłyn','Młynary','Morąg','Mrągowo','Nidzica','Nowe Miasto Lubawskie','Olecko','Olsztyn','Olsztynek','Orneta','Orzysz','Ostróda','Pasłęk','Pasym','Pieniężno','Pisz','Reszel','Ruciane-Nida','Ryn','Sępopol','Susz','Szczytno','Tolkmicko','Węgorzewo','Zalewo');
    for i in 1..1000 loop
        lastName := lastNames(i);
        firstName := firstNames(rand(firstNames.count));
        street := streets(rand(streets.count));
        houseNumber := mod((i+5)*3,30);
        city := cities(rand(cities.count));
        flatNumber := mod(i,100);
		INSERT INTO clients VALUES (NULL,lastName,firstName,street,houseNumber,city,flatNumber,0);
    end loop;
	commit;
END;
/

CREATE OR REPLACE PROCEDURE gen_orders IS 
    dateOfPlacement date;
    clientID int;
BEGIN
	for i in 1..1000 loop
        dateOfPlacement := TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '1990-01-01','J'),TO_CHAR(DATE '2018-12-31','J'))),'J');
        clientID := rand(1000);
        
		INSERT INTO orders VALUES (NULL,dateOfPlacement,clientId);
    end loop;
	commit;
END;
/

CREATE OR REPLACE PROCEDURE gen_products IS 
	TYPE TABSTR IS TABLE OF VARCHAR2(255);
	name TABSTR;
	qname NUMBER(5);
	quanity int;
    price int;
BEGIN
	name := TABSTR ('Bluza', 'Spodnie', 'Koszulka', 'Kamizelka', 'Skarpetki', 'Czapka z pomponem', 'Sweter', 'Bluza rozpinana', 'Kurtka', 'Kalesony');
	qname := name.count;
	FOR i IN 1..qname LOOP
		quanity := rand(20);
        price := dbms_random.value(500,10000);
		INSERT INTO products VALUES (NULL, name(i), quanity,price);
	END LOOP;
	commit;
END;
/

CREATE OR REPLACE PROCEDURE gen_delivers IS 
    supplierName varchar(255);
    dateOfPlacement date;
    
    TYPE tabstr IS TABLE OF VARCHAR2(255);
    suppliers tabstr;
BEGIN
    suppliers := tabstr('Ciuchex','Dostawczak','Magilak','Herber','Drunik','Kalafiorek','Truskaw','Ciucholand','SuperFirma');
	for i in 1..100 loop
        dateOfPlacement := TO_DATE(TRUNC(DBMS_RANDOM.VALUE(TO_CHAR(DATE '1990-01-01','J'),TO_CHAR(DATE '2018-12-31','J'))),'J');
        supplierName := suppliers(rand(suppliers.count));
		INSERT INTO deliver VALUES (NULL,supplierName,dateOfPlacement);
    end loop;
	commit;
END;
/

CREATE OR REPLACE PROCEDURE gen_orders_products IS 
    orderID int;
    productID int;
    quanity int;
BEGIN
	for i in 1..2000 loop
        orderID:= rand(1000);
        productID:= rand(10);
        quanity:= rand(2);
		INSERT INTO orders_products VALUES (orderID,productID,quanity);
    end loop;
	commit;
END;
/

CREATE OR REPLACE PROCEDURE gen_deliver_products IS 
    deliverID int;
    productID int;
    quanity int;
BEGIN
	for i in 1..100 loop
        deliverID:= rand(100);
        productID:= rand(10);
        quanity:= rand(500);
		INSERT INTO deliver_products VALUES (deliverID,productID,quanity);
    end loop;
	commit;
END;
/

------------generowanie danych w tabelach

DELETE FROM orders_products;
DELETE FROM deliver_products;
DELETE FROM orders;
DELETE FROM deliver;
DELETE FROM products;
DELETE FROM clients;

exec reset_seq( 'clients_seq' );
exec reset_seq('orders_seq');
exec reset_seq( 'products_seq' );
exec reset_seq( 'deliver_seq' );

exec gen_clients();
exec gen_orders();
exec gen_products();
exec gen_delivers();
exec gen_deliver_products();
exec gen_orders_products();


--------------------------------------------------------------
---nie poprawny insert------------

--jezeli chcemy zamowic wiecej produktow niz jest w magazynie to wylatujemy na bledzie
INSERT INTO orders_products VALUES (1,2,100000);--(orderID,productID,quanity)

-------------------------------indexy

EXECUTE DBMS_STATS.GATHER_TABLE_STATS ('mkasprzy','clients');

drop index idx0;
create index idx0 on clients(city);
drop index idx1;
create index idx1 on clients(id, city);
drop index idx2;
create index idx2 on clients(firstName);
drop index idx3;
create index idx3 on orders(clientID);
drop index idx4;
create index idx4 on products(name);
drop index idx5;
create index idx5 on clients(flatNumber);


alter index idx0 visible;
alter index idx1 visible;
alter index idx2 visible;
alter index idx3 visible;
alter index idx4 visible;
alter index idx5 visible;

--numery mieszkan sa od 1 do 100
--wyznaczona granica dla której range scan przechodzi w fast full scan to 31 procent calej tabeli clients
explain plan for
select flatNumber from clients where flatNumber>67 order by 1; --index range scan
select *
from table (dbms_xplan.display);
select count(*)/1001 from clients where flatNumber>67 order by 1;

explain plan for
select flatNumber from clients where flatNumber>66 order by 1; --fast full scan
select *
from table (dbms_xplan.display);
select count(*)/1001 from clients where flatNumber>66 order by 1;


--------------------------------------przykladowe selecty


--wartość sprzedazy poszczegolnych produktów w złotówkach
select p.name, sum(op.quanity*p.price/100) as wartosc_sprzedaży
from orders_products op join products p on op.productID = p.ID
group by p.name
order by sum(op.quanity*p.price) desc;

--produkty zamowione przez klientów o imionach Ada, Adam, Agata
select p.name, sum(op.quanity) as suma_produktów
from orders_products op join products p on op.productID = p.ID
where op.orderID in(
                select orders.id
                from orders join clients on orders.clientId= clients.Id
                where clients.firstName in ('Adam','Ada','Agata'))
group by p.name
order by sum(op.quanity) desc;

--daty wszystkich dostaw odebranych od firmy Ciucholand
select dateofdeliver as dzień_Miesiąc_Rok
from deliver
where supplierName = 'Ciucholand'
order by 1 desc;

---produkty dostarczone przez firme o nazwie Dostawczak
select p.name, sum(dp.quanity) as suma_dostaw
from deliver_products dp join products p on dp.productID = p.ID
where dp.deliverID in(
                select id
                from deliver
                where supplierName = 'Dostawczak')
group by p.name
order by sum(dp.quanity) desc;

--ilosc zamowien w złożona z poszczególnych miast

select c.city, count(o.id) as ilosc_zamowien
from clients c join orders o on c.id = o.clientId
group by c.city
order by 2 desc;


----------------------hinty

-- /*+use_merge(orders clients)*/
-- /*+use_hash(orders clients)*/
-- /*+use_nl(orders clients)*/

------------------hashjoin
explain plan for
select /* */ orders.id , orders.clientID, clients.id, clients.lastName
from orders join clients on orders.ClientId+1=clients.id+5
where orders.id+1 between 100 and 10000
order by clients.id;

select *
from table (dbms_xplan.display);

explain plan for
select /*+use_merge(orders clients) */ orders.id , orders.clientID, clients.id, clients.lastName
from orders join clients on orders.ClientId+1=clients.id+5
where orders.id+1 between 100 and 10000
order by clients.id;

select *
from table (dbms_xplan.display);

explain plan for
select /*+use_nl(orders clients) */ orders.id , orders.clientID, clients.id, clients.lastName
from orders join clients on orders.ClientId+1=clients.id+5
where orders.id+1 between 100 and 10000
order by clients.id;

select *
from table (dbms_xplan.display);


-----------------nasted loop
explain plan for
select /* */ orders.id , orders.clientID, clients.id, clients.lastName
from orders join clients on orders.ClientId=clients.id
where orders.id  between 205 and 210;

select *
from table (dbms_xplan.display);

explain plan for
select /*+use_hash(orders clients) */ orders.id , orders.clientID, clients.id, clients.lastName
from orders join clients on orders.ClientId=clients.id
where orders.id  between 205 and 210;

select *
from table (dbms_xplan.display);

explain plan for
select /*+use_merge(orders clients) */ orders.id , orders.clientID, clients.id, clients.lastName
from orders join clients on orders.ClientId=clients.id
where orders.id  between 205 and 210;

select *
from table (dbms_xplan.display);



