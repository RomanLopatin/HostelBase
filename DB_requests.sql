SELECT id FROM hotel_info
	WHERE city_id = 5;

-- все комнаты в отел€х города N 
SELECT * FROM room_info 
	WHERE hotel_id in (SELECT id FROM hotel_info
						WHERE city_id = 5);
						
-- все визиты в отел€х города N 
select 
	rv.arrival_date,
	rv.departure_date,
	rv.price,
	ri.bed_variation
from 
	room_visit rv
JOIN 
	(SELECT * FROM room_info 
	WHERE hotel_id in (SELECT id FROM hotel_info
						WHERE city_id = 3)) ri 
WHERE rv.hotel_id = ri.hotel_id;


-- все комнаты:
SELECT
	c.name AS CITY,
	hi.title,
	ri.id,
 	ri.base_price,
 	ri.bed_variation	
FROM
	room_info ri 
JOIN
	hotel_info hi ON hi.id = ri.hotel_id
JOIN 
	(SELECT name, id FROM city
	WHERE city.id = 5) c ON c.id = hi.city_id
;


-- комнаты, зан€тые ( в который нельз€ поселить) в период окт€брь 2020 (хоть 1 день периода зан€т)
SELECT
	ri.id room_id
FROM
	(SELECT id FROM city
	WHERE city.id = 5) c 
JOIN
	hotel_info hi ON c.id = hi.city_id
JOIN 
	room_info ri ON hi.id = ri.hotel_id
JOIN 
	room_visit rv ON ri.id = rv.room_id 
WHERE rv.arrival_date <= "2020-10-30" and rv.departure_date > "2020-10-01"
;

-- комнаты '1 twin', в которые можно поселить с 1 по 30 окт€бр€ 2020 в городе id = 5
-- отбор 3-х лучших предложений по цене 
SELECT
	c.name AS city,
	hi.title hotel_name,
	hi.hotel_class, 
	hi.hotel_type, 
	ri.id,
 	ri.base_price,
 	ri.bed_variation
FROM
	(SELECT name, id FROM city WHERE city.id = 5) c
JOIN
	hotel_info hi ON c.id = hi.city_id
JOIN 
	(SELECT * FROM room_info ri where ri.bed_variation = '1 twin') ri ON hi.id = ri.hotel_id
where ri.id not in (SELECT ri.id room_id
					FROM
						(SELECT id FROM city WHERE city.id = 5) c 
					JOIN
						hotel_info hi ON c.id = hi.city_id
					JOIN 
						room_info ri ON hi.id = ri.hotel_id
					JOIN 
						room_visit rv ON ri.id = rv.room_id 
					WHERE rv.arrival_date <= "2020-10-30" and rv.departure_date > "2020-10-01")
ORDER BY ri.base_price 
LIMIT 3
;

-- группировка доступных комнат по классу во всех городах в кторые можно поселитьс€ с 1 по 30 окт€бр€ 2020
SELECT
	c.name,
	hi.hotel_class,
	count(ri.id)
FROM
	city c
JOIN
	hotel_info hi ON c.id = hi.city_id
JOIN 
	(SELECT * FROM room_info ri where ri.bed_variation = '1 twin') ri ON hi.id = ri.hotel_id
where ri.id not in (SELECT ri.id room_id
					FROM
						(SELECT id FROM city WHERE city.id = 5) c 
					JOIN
						hotel_info hi ON c.id = hi.city_id
					JOIN 
						room_info ri ON hi.id = ri.hotel_id
					JOIN 
						room_visit rv ON ri.id = rv.room_id 
					WHERE rv.arrival_date <= "2020-10-30" and rv.departure_date > "2020-10-01")
GROUP BY c.name, hi.hotel_class 
ORDER BY c.name,hi.hotel_class 
;

-- сколько детей и взрослых в отеле проживает на дату, сколько вег. завтраков, сколько трансферов
SELECT
	rv.hotel_id,
	SUM(vd.adults_nomber) adults,
	SUM(vd.children_nomber) children,
	SUM(vd.veg_breafast_nomber) veg_breafast,
	SUM(vd.transfer_in_needed) transfer_in,
	SUM(vd.transfer_out_needed) transfer_out
FROM 
	(SELECT * FROM room_visit rv WHERE (rv.arrival_date <= "2020-12-01" 
										and rv.departure_date >= "2020-12-01" )) rv
JOIN
	(SELECT * FROM visit_details) vd
ON rv.id = vd.room_visit_id
GROUP BY rv.hotel_id 
;

-- комнаты по отел€м на 1 окт 2020 (зан€тые и общее число)
SELECT
	total.title,
	occupied.OCCUPIED,
	total.TOTAL_NUMBER
FROM
	(SELECT
		hi.title, 
		hi.id HOTEL_id, 
		count(ri.id) TOTAL_NUMBER 
	FROM
		hotel_info hi 
	JOIN 
		room_info ri ON hi.id = ri.hotel_id
	GROUP BY hi.id) total
JOIN
	(SELECT 
		hi.id HOTEL_id, 
		count(ri.id) OCCUPIED 
	FROM
		hotel_info hi 
	JOIN 
		room_info ri ON hi.id = ri.hotel_id
	JOIN 
		room_visit rv ON ri.id = rv.room_id 
	WHERE rv.arrival_date <= "2020-10-01" and rv.departure_date > "2020-10-01"
	GROUP BY hi.id) occupied 
ON total.HOTEL_id = occupied.HOTEL_id 
;

-- √орода лидиры заселению отелей на дату, тройка лидеров
SELECT
	c.name,
	sum(vd.adults_nomber) adults,
	sum(vd.children_nomber) children,
	sum(vd.adults_nomber) + sum(vd.children_nomber) people
FROM hotel_info hi  
join
	(SELECT * FROM room_visit rv WHERE (rv.arrival_date <= "2020-12-01" 
										and rv.departure_date >= "2020-12-01" )) rv
ON hi.id = rv.hotel_id 
JOIN
	visit_details vd
ON rv.id = vd.room_visit_id
JOIN 
	city c 
ON c.id = hi.city_id 
GROUP BY hi.city_id 
ORDER by people DESC
LIMIT 3
; 

--ѕ–≈ƒ—“ј¬Ћ≈Ќ»я

-- представление дл€ бытрого получени€ информации о детал€х заездов на дату
CREATE VIEW arrivel_ditails AS 
	SELECT
		c.name,
		hi.title,
		rv.hotel_id,
		rv.room_id,
		round(rv.price,2),
		(vd.adults_nomber) adults,
		(vd.children_nomber) children,
		(vd.transfer_in_needed) transfer_in,
		rv.arrival_date,
		rv.departure_date 
	FROM
		room_visit rv
		-- (SELECT * FROM room_visit rv WHERE rv.arrival_date = "2020-07-24") rv
	JOIN
		visit_details vd ON rv.id = vd.room_visit_id
	JOIN
		hotel_info hi ON hi.id = rv.hotel_id 
	JOIN
		city c ON c.id = hi.city_id 	
;

--получение информации о заселени€х на дату на основе представлени€
select * from arrivel_ditails
where arrival_date = "2020-07-24"; 


-- представление где покушать недалеко от отел€
CREATE VIEW where_to_go_view AS 
	SELECT 
		wtgfh.hotel_id,
		wtg.catigory_to_go,
		wtg.title,
		wtgfh.distance_from_hotel,
		wtgfh.directions 
	FROM
		where_to_go_from_hotel wtgfh
	JOIN
		where_to_go wtg
	ON 
		wtgfh.where_to_go_id = wtg.id
	ORDER BY wtgfh.hotel_id, wtg.catigory_to_go, wtgfh.distance_from_hotel   
;

-- на основе представлени€ посмотрим куда можно сходить из отел€ 53
SELECT 
	*
FROM 
	where_to_go_view wtgV
WHERE
	wtgV.hotel_id = 53
;

-- “–»√√≈–џ Ќј —ќЅџ“»я ¬—“ј¬ »/ќЅЌќ¬Ћ≈Ќ»я »Ќ‘ќ–ћј÷»» ¬ Ѕƒ ќ ¬»«»“ј’
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

UPDATE room_visit
	set departure_date = '2021-07-16'
	where id = 600;

SELECT @room_visit_last_updated;

-- ѕроверка ¬—“ј¬ »/ќЅЌќ¬Ћ≈Ќ»я деталей визита 
DROP TRIGGER IF EXISTS room_visit_details_check; 
CREATE TRIGGER room_visit_details_check BEFORE UPDATE ON visit_details
FOR EACH ROW
	BEGIN 
		IF NEW.adults_nomber > 1 THEN 
			signal SQLSTATE '45000' SET MESSAGE_TEXT = 'INSERT CENSELLED!';
		END IF;	
	END;



















			
