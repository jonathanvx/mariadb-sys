
DROP PROCEDURE IF EXISTS show_recommendations;
DELIMITER $$

CREATE PROCEDURE show_recommendations()
BEGIN
    SELECT * FROM recommend_compression;
    SELECT * FROM recommend_drop_indexes;
    SELECT * FROM recommend_fix_unoptimised_queries;

END $$
DELIMITER ;

