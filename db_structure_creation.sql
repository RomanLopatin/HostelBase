
DROP DATABAE IF EXISTS hotel_reservation;
CREATE DATABASE hotel_reservation; 

DROP TABLE IF EXISTS city;
CREATE TABLE city (
	id SERIAL ,
	name VARCHAR(32),
	INDEX city_name_ndx(name(10))
);

INSERT INTO city (name) 
	VALUES ('Moscow'),('Kaluga'), ('Penza'), ('Riga'), ('Omsk');

DROP TABLE IF EXISTS guest_category_discount;
CREATE TABLE guest_category_discount(
    category_name ENUM('bronze', 'silver', 'gold', 'platinum') UNIQUE,
    discount_percent TINYINT UNSIGNED
 );

INSERT INTO guest_category_discount (category_name, discount_percent) 
	VALUES ('bronze', 0), ('silver', 2), ('gold', 5), ('platinum', 10);

	
DROP TABLE IF EXISTS hotel_info;
CREATE TABLE hotel_info (
	id SERIAL PRIMARY KEY,
	city_id BIGINT UNSIGNED NOT NULL,
	title VARCHAR(128),
	description TEXT,
    hotel_type ENUM('guest house', 'hotel', 'hostel'),
    hotel_class ENUM('econom', 'comfort', 'premium'),
	distance_from_city_centre FLOAT CHECK (distance_from_city_centre > 0 AND distance_from_city_centre <999),
	rating FLOAT UNSIGNED CHECK (rating <10),
	location_rating FLOAT UNSIGNED CHECK (location_rating <10),
	address_line VARCHAR(255),
	phone_no BIGINT UNSIGNED UNIQUE,
	email VARCHAR(128) UNIQUE,
	INDEX hotel_city_rating_ndx(city_id, rating),
	FOREIGN KEY (city_id) REFERENCES city(id)
);


DROP TABLE IF EXISTS guest_info;
CREATE TABLE guest_info (
	id SERIAL PRIMARY KEY,
	firstname VARCHAR(32),
    lastname VARCHAR(32),
    email VARCHAR(128) UNIQUE,
	phone INT UNSIGNED UNIQUE,
	INDEX guest_ndx(lastname(10), firstname (10))
);

ALTER TABLE guest_info 
ADD COLUMN guest_category ENUM('bronze', 'silver', 'gold', 'platinum') DEFAULT 'bronze', 
ADD FOREIGN KEY (guest_category) REFERENCES guest_category_discount(category_name);

DROP TABLE IF EXISTS room_info;
CREATE TABLE room_info (
	id SERIAL PRIMARY KEY,
	hotel_id BIGINT UNSIGNED NOT NULL, 
	bed_variation ENUM('1 single', '2 single', '3 single', '1 twin'),
	breakfast_included BOOLEAN DEFAULT FALSE,
	own_kitchen BOOLEAN DEFAULT FALSE,
	free_cancelation BOOLEAN DEFAULT FALSE, 
	base_price FLOAT UNSIGNED DEFAULT NULL, 
	INDEX hotel_room_ndx(hotel_id, id),
	FOREIGN KEY (hotel_id) REFERENCES hotel_info(id)
);

ALTER TABLE room_info ADD CONSTRAINT fk_hotel_id
	FOREIGN KEY (hotel_id) REFERENCES hotel_info(id)
	ON UPDATE CASCADE
	ON DELETE RESTRICT;

DROP TABLE IF EXISTS hotel_pictures;
CREATE TABLE hotel_pictures(
	id SERIAL,
    hotel_id BIGINT UNSIGNED NOT NULL,
    room_id BIGINT UNSIGNED DEFAULT NULL, -- if room_id == NULL then this is hotel's picture! 
	image_url VARCHAR(255),
	INDEX picture_ndx(id, hotel_id, room_id),
    FOREIGN KEY (hotel_id) REFERENCES hotel_info(id),
    FOREIGN KEY (room_id) REFERENCES room_info(id)
);

DROP TABLE IF EXISTS room_visit;
CREATE TABLE room_visit (
	id SERIAL,
	hotel_id BIGINT UNSIGNED NOT NULL,
	room_id BIGINT UNSIGNED NOT NULL,
	guest_id BIGINT UNSIGNED NOT NULL,
	arrival_date DATE NOT NULL, 
	departure_date DATE NOT NULL, 
	FOREIGN KEY (room_id) REFERENCES room_info(id),
	FOREIGN KEY (hotel_id) REFERENCES hotel_info(id),
	FOREIGN KEY (guest_id) REFERENCES guest_info(id),
	CHECK (arrival_date < departure_date),
	PRIMARY KEY(arrival_date, hotel_id, room_id)
	-- created_at DATETIME DEFAULT NOW(),
    -- updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
);

ALTER TABLE room_visit ADD price FLOAT DEFAULT 0;

ALTER TABLE room_visit 
	ADD created_at DATETIME DEFAULT NOW(),
	ADD updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP;



DROP TABLE IF EXISTS visit_details;
CREATE TABLE visit_details (
	id SERIAL PRIMARY KEY,
	room_visit_id BIGINT UNSIGNED NOT NULL,
	adults_nomber TINYINT UNSIGNED,
	children_nomber TINYINT UNSIGNED,
	veg_breafast_nomber TINYINT UNSIGNED,
	non_veg_breafast_nomber TINYINT UNSIGNED,
	transfer_in_needed BOOL,
	transfer_out_needed BOOL,
	transfer_in_details TEXT,
	transfer_OUT_details TEXT,
	FOREIGN KEY (room_visit_id) REFERENCES room_visit(id),
	created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
);
	
DROP TRIGGER IF EXISTS room_visit_details_check_on_update;
CREATE TRIGGER room_visit_details_check_on_update BEFORE UPDATE ON visit_details
FOR EACH ROW
	BEGIN
		DECLARE ri_id INT;
		DECLARE b_var TINYTEXT;
		set @rvi = old.room_visit_id;
  		SELECT room_id INTO ri_id FROM room_visit WHERE id  = @rvi LIMIT 1;
		SELECT bed_variation into b_var  FROM room_info WHERE room_info.id = ri_id LIMIT 1;
		
		IF (b_var = '1 single' and new.adults_nomber > 1) OR 
		   (b_var = '2 single' and new.adults_nomber > 2) OR 
		   (b_var = '3 single' and new.adults_nomber > 3) OR 
		   (b_var = '1 twin' and new.adults_nomber > 2) THEN 
			signal SQLSTATE '45000' SET MESSAGE_TEXT = 'UPDATE CENSELLED!';
		END IF;	
	END;


DROP TRIGGER IF EXISTS room_visit_details_check_on_insert;
CREATE TRIGGER room_visit_details_check_on_insert BEFORE INSERT ON visit_details
FOR EACH ROW
	BEGIN
		DECLARE ri_id INT;
		DECLARE b_var TINYTEXT;
		set @rvi = new.room_visit_id;
  		SELECT room_id INTO ri_id FROM room_visit WHERE id  = @rvi LIMIT 1;
		SELECT bed_variation into b_var  FROM room_info WHERE room_info.id = ri_id LIMIT 1;
		
		IF (b_var = '1 single' and new.adults_nomber > 1) OR 
		   (b_var = '2 single' and new.adults_nomber > 2) OR 
		   (b_var = '3 single' and new.adults_nomber > 3) OR 
		   (b_var = '1 twin' and new.adults_nomber > 2) THEN 
			signal SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT CENSELLED!';
		END IF;	
	END;

-- ÒÐÈÃÃÅÐÛ ÍÀ ÑÎÁÛÒÈß ÂÑÒÀÂÊÈ/ÎÁÍÎÂËÅÍÈß ÈÍÔÎÐÌÀÖÈÈ Â ÁÄ Î ÂÈÇÈÒÀÕ
DROP TRIGGER IF EXISTS room_visit_last_inserted;
CREATE TRIGGER room_visit_last_inserted AFTER INSERT ON room_visit
FOR EACH ROW
	BEGIN
		SET @room_visit_last_change = now(); 
	END;


DROP TRIGGER IF EXISTS room_visit_last_updated;
CREATE TRIGGER room_visit_last_updated AFTER UPDATE ON room_visit
FOR EACH ROW
	BEGIN
		SET @room_visit_last_change = now(); 
	END;



DROP TABLE IF EXISTS where_to_go;
CREATE TABLE where_to_go (
	id SERIAL,
	city_id BIGINT UNSIGNED NOT NULL,
	catigory_to_go ENUM('cafe', 'restorant', 'bar', 'museum', 'beach', 'park', 'other'),
	title VARCHAR(128),
	address VARCHAR(255),
	description TEXT,
	web_page VARCHAR (128),
	INDEX (city_id, catigory_to_go)
);


DROP TABLE IF EXISTS where_to_go_from_hotel;
CREATE TABLE where_to_go_from_hotel (
	id SERIAL,
	hotel_id BIGINT UNSIGNED NOT NULL, 
	where_to_go_id BIGINT UNSIGNED NOT NULL,
	distance_from_hotel FLOAT UNSIGNED CHECK (distance_from_hotel > 0 AND distance_from_hotel <10),
	directions Text,
	INDEX (hotel_id),
	FOREIGN KEY (where_to_go_id) REFERENCES where_to_go(id),
	FOREIGN KEY (hotel_id) REFERENCES hotel_info(id)
);

ALTER TABLE where_to_go_from_hotel
ADD CONSTRAINT fk_where_to_go_id
	FOREIGN KEY (where_to_go_id) REFERENCES where_to_go(id)
	ON UPDATE CASCADE
	ON DELETE CASCADE;





