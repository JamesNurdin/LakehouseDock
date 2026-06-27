/*
   Distribution of information‑type values by gender.
   For each info_type (the "info" column from the info_type table) the query returns:
   - total number of person_info rows
   - distinct persons (name.id) contributing those rows
   - counts and distinct‑person counts split by gender (M/F)
   - average length of the person_info.info text
   The result is ordered by the total number of entries and limited to the top 20 types.
*/
WITH info_detail AS (
    SELECT
        pi.id AS person_info_id,
        pi.info AS person_info,
        pi.note,
        pi.person_id,
        pi.info_type_id,
        n.id AS name_id,
        n.gender,
        it.info
    FROM person_info pi
    JOIN name n
        ON pi.person_id = n.id
    JOIN info_type it
        ON pi.info_type_id = it.id
)
SELECT
    info,
    COUNT(*) AS total_entries,
    COUNT(DISTINCT name_id) AS total_distinct_persons,
    SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_entries,
    COUNT(DISTINCT IF(gender = 'M', name_id, NULL)) AS male_distinct_persons,
    SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_entries,
    COUNT(DISTINCT IF(gender = 'F', name_id, NULL)) AS female_distinct_persons,
    AVG(length(person_info)) AS avg_info_length
FROM info_detail
GROUP BY info
ORDER BY total_entries DESC
LIMIT 20
