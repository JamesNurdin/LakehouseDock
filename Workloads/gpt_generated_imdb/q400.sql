SELECT
    it.id AS info_type_id,
    it.info AS info_type_desc,
    COUNT(DISTINCT pi.person_id) AS distinct_persons,
    COUNT(*) AS total_entries,
    AVG(LENGTH(pi.info)) AS avg_info_length,
    SUM(CASE WHEN pi.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
FROM
    person_info AS pi
JOIN
    info_type AS it
    ON pi.info_type_id = it.id
GROUP BY
    it.id,
    it.info
ORDER BY
    total_entries DESC
