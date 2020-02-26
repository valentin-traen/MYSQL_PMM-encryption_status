CREATE TABLE mysql.pmm_custom_informations_keys_rotation
(
  master_key_type ENUM('innodb','binary') PRIMARY KEY,
  master_key_number smallint,
  master_key_creation_date VARCHAR(10),
  master_key_next_rotation VARCHAR(10)
);


DROP PROCEDURE IF EXISTS mysql.generate_innodb_master_key;
delimiter //
CREATE PROCEDURE mysql.generate_innodb_master_key()
BEGIN
DECLARE master_key_creation_date VARCHAR(10);
DECLARE master_key_next_rotation VARCHAR(10);
DECLARE master_key_number SMALLINT;
DECLARE master_key_exists TINYINT;

ALTER INSTANCE ROTATE INNODB MASTER KEY;

SELECT CURRENT_DATE INTO master_key_creation_date;
SELECT MAX(SUBSTRING_INDEX(KEY_ID, '-', -1)) INTO master_key_number FROM performance_schema.keyring_keys WHERE KEY_ID REGEXP '^(INNODBKey).*-[0-9]+$';
SELECT EXISTS(SELECT * from mysql.pmm_custom_informations_keys_rotation WHERE master_key_type='innodb') INTO master_key_exists;
SELECT DATE(STARTS) FROM information_schema.EVENTS WHERE EVENT_NAME = 'event_rotate_innodb_master_key' INTO master_key_next_rotation;

IF master_key_exists THEN
UPDATE mysql.pmm_custom_informations_keys_rotation SET master_key_number=master_key_number,master_key_creation_date=master_key_creation_date,master_key_next_rotation=master_key_next_rotation WHERE master_key_type='innodb';
ELSE
INSERT INTO mysql.pmm_custom_informations_keys_rotation VALUES ('innodb',master_key_number,master_key_creation_date,master_key_next_rotation);
END IF;
END //
delimiter ;


DROP EVENT IF EXISTS mysql.event_rotate_innodb_master_key;
CREATE DEFINER = 'root'@'localhost' EVENT mysql.event_rotate_innodb_master_key
  ON SCHEDULE
    EVERY 7 DAY
    STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY + INTERVAL 1 HOUR)
  DO
  CALL mysql.generate_innodb_master_key();




DROP PROCEDURE IF EXISTS mysql.generate_binary_master_key;
delimiter //
CREATE PROCEDURE mysql.generate_binary_master_key()
BEGIN
DECLARE master_key_creation_date VARCHAR(10);
DECLARE master_key_next_rotation VARCHAR(10);
DECLARE master_key_number SMALLINT;
DECLARE master_key_exists TINYINT;

ALTER INSTANCE ROTATE BINLOG MASTER KEY;

SELECT CURRENT_DATE INTO master_key_creation_date;
SELECT MAX(SUBSTRING_INDEX(KEY_ID, '_', -1)) INTO master_key_number FROM performance_schema.keyring_keys WHERE KEY_ID REGEXP '^(MySQLReplicationKey).*_[0-9]+$';
SELECT EXISTS(SELECT * from mysql.pmm_custom_informations_keys_rotation WHERE master_key_type='binary') INTO master_key_exists;
SELECT DATE(STARTS) FROM information_schema.EVENTS WHERE EVENT_NAME = 'event_rotate_innodb_master_key' INTO master_key_next_rotation;

IF master_key_exists THEN
UPDATE mysql.pmm_custom_informations_keys_rotation SET master_key_number=master_key_number,master_key_creation_date=master_key_creation_date,master_key_next_rotation=master_key_next_rotation WHERE master_key_type='binary';
ELSE
INSERT INTO mysql.pmm_custom_informations_keys_rotation VALUES ('binary',master_key_number,master_key_creation_date,master_key_next_rotation);
END IF;
END //
delimiter ;


DROP EVENT IF EXISTS mysql.event_rotate_binary_master_key;
CREATE DEFINER = 'root'@'localhost' EVENT mysql.event_rotate_binary_master_key
  ON SCHEDULE
    EVERY 30 DAY
    STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY + INTERVAL 1 HOUR)
  DO
  CALL mysql.generate_binary_master_key();
