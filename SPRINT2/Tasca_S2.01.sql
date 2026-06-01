-- Exercici 1
-- A partir dels documents adjunts (estructura_dades i dades_introduir), importa les dues taules. Mostra les característiques principals 
-- de l'esquema creat i explica les diferents taules i variables que existeixen. Assegura't d'incloure un diagrama que il·lustri la relació
-- entre les diferents taules i variables.

USE transactions;

-- Exercici 2
-- Utilitzant JOIN realitzaràs les següents consultes:
-- Llistat dels països que estan generant vendes.

SELECT DISTINCT country Països
FROM company c
JOIN transaction t
ON c.id = t.company_id; 

-- Des de quants països es generen les vendes.

SELECT COUNT(DISTINCT country) num_països
FROM company c
JOIN transaction t
ON c.id = t.company_id;

-- Identifica la companyia amb la mitjana més gran de vendes.

SELECT c.id, c.company_name nom_companyia, ROUND(AVG(amount),2) as mitjana_vendes
FROM company c 
JOIN transaction t
ON c.id = t.company_id
GROUP BY c.id, c.company_name
ORDER BY mitjana_vendes DESC
LIMIT 1;

-- Exercici 3
-- Utilitzant només subconsultes (sense utilitzar JOIN):
-- Mostra totes les transaccions realitzades per empreses d'Alemanya.

SELECT t.id ID_Transaccions 
FROM transaction t
WHERE t.company_id IN 
	(SELECT c.id 
    FROM company c
    WHERE country = 'Germany'
    );
    
-- Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.

SELECT c.id, c.company_name nom_companyia
FROM company c
WHERE c.id IN (
	SELECT t.company_id 
    FROM transaction t
    WHERE t.amount > (
    SELECT AVG(amount) 
    FROM transaction
    ));
    
-- Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.

SELECT id, company_name nom_companyia
FROM company 
WHERE id NOT IN ( 
	SELECT company_id 
    FROM transaction 
    WHERE company_id IS NOT NULL
    );

-- Exercici 4
-- La teva tasca és dissenyar i crear una taula anomenada "credit_card" que emmagatzemi detalls crucials sobre les targetes de crèdit.
-- La nova taula ha de ser capaç d'identificar de manera única cada targeta i establir una relació adequada amb les altres dues taules
-- ("transaction" i "company"). Després de crear la taula serà necessari que ingressis la informació del document denominat "dades_introduir_credit".
-- Recorda mostrar el diagrama i realitzar una breu descripció d'aquest.

CREATE TABLE credit_card(
	id VARCHAR (100),
    iban VARCHAR (100) NOT NULL,
    pan VARCHAR (100) NOT NULL,
    pin VARCHAR (100) NOT NULL,
    cvv INT NOT NULL,
    expiring_date VARCHAR(10) NOT NULL,
    PRIMARY KEY (id),
    INDEX (id)
    );
    
    DESCRIBE  credit_card;
    
    
    SELECT *
    FROM credit_card;
    
UPDATE credit_card
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%y')
WHERE expiring_date LIKE '__/__/__';

UPDATE credit_card
SET expiring_date = STR_TO_DATE(expiring_date, '%d/%m/%Y')
WHERE expiring_date LIKE '__/__/____';

ALTER TABLE credit_card
MODIFY expiring_date DATE NOT NULL;

ALTER TABLE transaction
ADD CONSTRAINT fk_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);


-- Exercici 5
-- El departament de Recursos Humans ha identificat un error en el número de compte associat a la targeta de crèdit amb ID CcU-2938. 
-- La informació que ha de mostrar-se per a aquest registre és: TR323456312213576817699999. Recorda mostrar que el canvi es va realitzar.

SELECT iban
FROM credit_card
WHERE id = 'CcU-2938';

UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

SELECT iban
FROM credit_card
WHERE id = 'CcU-2938';


-- Exercici 6
-- En la taula "transaction" ingressa una nova transacció amb la següent informació:
-- Id 
-- 108B1D1D-5B23-A76C-55EF-C568E49A99DD 
-- credit_card_id 
-- CcU-9999 
-- company_id 
-- b-9999 
-- user_id 
-- 9999 
-- lat 
-- 829.999 
-- longitude 
-- -117.999 
-- amount 
-- 111.11 
-- declined 
-- 0 
INSERT INTO credit_card(
	id,
    iban,
    pan,
    pin,
    cvv,
    expiring_date
    )
    VALUES (
    'CcU-9999',
    'XX4857591835292505850772',
    '2321345643564378',
    '5465',
    565,
     STR_TO_DATE('21/05/2026', '%d/%m/%Y')
    );
    
    INSERT INTO company (
    id
    )
    VALUES (
    'b-9999'
    );

INSERT INTO transaction (id, 
	credit_card_id,
    company_id,
    user_id, 
    lat,
    longitude,
    timestamp, 
    amount,
    declined
    ) 
    VALUES (
    '108B1D1D-5B23-A76C-55EF-C568E49A99DD', 
	'CcU-9999',
	'b-9999',
	9999,
    829.999,
    -117.999,
    now(),
    111.11,
    0
    );

SELECT*
FROM transaction
WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';


-- Exercici 7
-- Des de recursos humans et sol·liciten eliminar la columna "pan" de la taula credit_card. Recorda mostrar el canvi realitzat.

SELECT *
FROM credit_card;

ALTER TABLE credit_card 
DROP COLUMN pan;

SELECT *
FROM credit_card;

-- Exercici 8
-- Descarrega els arxius CSV que trobaràs a l'apartat de recursos:

-- american_users.csv
-- european_users.csv
-- companies.csv
-- credit_cards.csv
-- transactions.csv
-- Estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, almenys 4 taules de les quals puguis realitzar 
-- les següents consultes:
-- La taula de products.csv l'utilitzarem més endavant.

DROP DATABASE IF EXISTS star_model;

CREATE DATABASE star_model;

USE star_model;

CREATE TABLE dim_users(
	id int PRIMARY KEY,
	name VARCHAR (100),
    surname VARCHAR (100),
    phone VARCHAR (100),
    email VARCHAR (150),
    birth_date VARCHAR (20),
    country VARCHAR (100),
    city VARCHAR (100),
    postal_code VARCHAR (100),
    address VARCHAR (100),
    signup_date DATE,
    user_segment VARCHAR (100),
    income_band VARCHAR (100)
    );
    
CREATE TABLE dim_credit_cards(
    id VARCHAR(20) PRIMARY KEY,
    user_id INT,
    iban VARCHAR(50),
    pan VARCHAR(30),
    pin CHAR(4), 
    cvv CHAR(3),
    track1 TEXT,
    track2 TEXT,
    expiring_date VARCHAR(10),                                                        -- format 07/26/28 VARCHAR → no és DATE    
    card_type VARCHAR(50),
    card_renewal_flag TINYINT(1)
    );
    
CREATE TABLE dim_companies (
    company_id VARCHAR(20) PRIMARY KEY,
    company_name VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(150),
    country VARCHAR(100),
    website VARCHAR(255),
    merchant_category VARCHAR(100),
    merchant_price_position INT
);

CREATE TABLE fact_transactions (
	id VARCHAR(255) PRIMARY KEY,
	card_id VARCHAR(20),
    business_id VARCHAR(20),
    timestamp DATETIME,
    amount DECIMAL(10,2),
    declined TINYINT(1),
    product_ids VARCHAR(255),
    user_id INT,lat DECIMAL(10,6),
    longitude DECIMAL(10,6),
    discount_amount DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    shipping_amount DECIMAL(10,2),
    channel VARCHAR(50),
    campaign_id VARCHAR(50),
    device_type VARCHAR(50),
    is_international TINYINT(1),
    decline_reason VARCHAR(255),
    distance_km DECIMAL(10,2)
);

-- DESCARREGAR ARXIUS

LOAD DATA LOCAL INFILE 'C:/Users/ALBERT/ESPECIALITZACIO/sql/New Database (1)/N1-Ex.8__credit_cards.csv'
INTO TABLE dim_credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; 

LOAD DATA LOCAL INFILE 'C:/Users/ALBERT/ESPECIALITZACIO/sql/New Database (1)/N1-Ex.8__companies.csv'
INTO TABLE dim_companies
FIELDS TERMINATED  BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE dim_companies
MODIFY COLUMN merchant_price_position VARCHAR(50);

DESCRIBE dim_companies;

LOAD DATA LOCAL INFILE 'C:/Users/ALBERT/ESPECIALITZACIO/sql/New Database (1)/N1-Ex.8__companies.csv'
REPLACE
INTO TABLE dim_companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT *
FROM dim_companies;

LOAD DATA LOCAL INFILE 'C:/Users/ALBERT/ESPECIALITZACIO/sql/New Database (1)/N1-Ex.8__transactions.csv'
INTO TABLE fact_transactions
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;     

select *
FROM fact_transactions;

LOAD DATA LOCAL INFILE 'C:/Users/ALBERT/ESPECIALITZACIO/sql/New Database (1)/N1-Ex.8__american_users.csv'
INTO TABLE dim_users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/ALBERT/ESPECIALITZACIO/sql/New Database (1)/N1-Ex.8__european_users.csv'
INTO TABLE dim_users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE fact_transactions
ADD CONSTRAINT fk_dim_credit_cards
FOREIGN KEY (card_id) REFERENCES
dim_credit_cards(id);

ALTER TABLE fact_transactions
ADD CONSTRAINT fk_dim_companies
FOREIGN KEY (business_id) REFERENCES
dim_companies(company_id);

ALTER TABLE fact_transactions
ADD CONSTRAINT fk_dim_users
FOREIGN KEY (user_id) REFERENCES
dim_users(id);

-- Exercici 9
-- Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules.

SELECT u.id, u.name nom, u.surname cognoms, t.total_transactions
FROM dim_users u
JOIN (SELECT user_id, COUNT(id) AS total_transactions
FROM fact_transactions
GROUP BY user_id) t
ON u.id = t.user_id
WHERE t.total_transactions > 80;


-- Exercici 10
-- Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.

SELECT cc.iban, ROUND(AVG(t.amount), 2) AS mitjana_amount
FROM fact_transactions t
JOIN dim_companies c
ON t.business_id = c.company_id
JOIN dim_credit_cards cc
ON cc.id = t.card_id
WHERE c.company_name = 'Donec Ltd'
GROUP BY cc.iban;

-- Nivell 2
-- Exercici 1
-- Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
-- Mostra la data de cada transacció juntament amb el total de les vendes.

SELECT DATE(timestamp) AS dia, SUM(amount) AS total
FROM fact_transactions
GROUP BY DATE(timestamp)
ORDER BY TOTAL DESC
LIMIT 5;

-- Exercici 2
-- Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions amb un valor comprès
-- entre 350 i 400 euros i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. 
-- Ordena els resultats de major a menor quantitat.

SELECT c.company_name nom_companyia, c.phone telefon , c.country pais, t.amount amount, t.timestamp time
FROM fact_transactions t
JOIN dim_companies c
ON t.business_id = c.company_id
WHERE t.amount BETWEEN 350.00 AND 400.00 
AND DATE(t.timestamp) IN (
	'2015/04/29',
    '2018/07/20',
    '2024/03/13')
ORDER BY t.amount DESC;

-- Exercici 3
-- Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi,
 -- per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses,
 -- però el departament de recursos humans és exigent i vol un llistat de les empreses on especifiquis si tenen
 -- igual o més de 400 transaccions o menys.
 
SELECT c.company_name companyia,
CASE
	WHEN COUNT(t.id) >= 400 THEN 'igual o mes de 400'
    ELSE 'menys de 400'
    END AS total_transactions
FROM fact_transactions t
JOIN dim_companies c
ON t.business_id = c.company_id
GROUP BY c.company_name;

-- Exercici 4
-- Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.

DELETE FROM fact_transactions WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Exercici 5
-- La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies efectives.
-- S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves transaccions. 
-- Serà necessària que creïs una vista anomenada VistaMarketing que contingui la següent informació: Nom de la companyia.
-- Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia. 
-- Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.

CREATE VIEW VistaMarketing AS
SELECT 
    c.company_name AS companyia,
    c.phone AS telefon,
    c.country AS pais,
    AVG(t.amount) AS mitjana_compra
FROM dim_companies c
JOIN fact_transactions t
      ON c.company_id = t.business_id
GROUP BY 
    c.company_name,
    c.phone,
    c.country;

SELECT *
FROM VistaMarketing;


-- Nivell 3
-- Exercici 1
-- Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres últimes transaccions han estat declinades aleshores és inactiu, si almenys una no és rebutjada aleshores és actiu. Partint d’aquesta taula respon:

-- Quantes targetes estan actives?


-- Exercici 2
-- Crea una taula amb la qual puguem unir les dades de l'arxiu de products.csv amb la base de dades creada (ja que fins ara no podíem fer-ho), tenint en compte que des de transaction tens product_ids. Genera la següent consulta:

-- Necessitem conèixer el nombre de vegades que s'ha venut cada producte.


    
    
    
    
    