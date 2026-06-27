/*
  Analytical query: For each gender, identify the most frequent info_type_id for each person
  (i.e., the info_type that appears the most for that person) and then aggregate how many
  persons share the same top info_type within each gender, along with the average count
  of that top info_type per person.
*/
WITH person_info_rank AS (
    SELECT
        pi.person_id,
        pi.info_type_id,
        COUNT(*) AS info_type_cnt,
        ROW_NUMBER() OVER (PARTITION BY pi.person_id ORDER BY COUNT(*) DESC) AS rn
    FROM person_info pi
    GROUP BY pi.person_id, pi.info_type_id
),
person_top_info AS (
    SELECT
        person_id,
        info_type_id AS top_info_type_id,
        info_type_cnt AS top_info_type_cnt
    FROM person_info_rank
    WHERE rn = 1
)
SELECT
    n.gender,
    pt.top_info_type_id,
    COUNT(*) AS persons_with_this_top_type,
    AVG(pt.top_info_type_cnt) AS avg_top_type_count
FROM name n
JOIN person_top_info pt
    ON pt.person_id = n.id
GROUP BY n.gender, pt.top_info_type_id
ORDER BY n.gender, pt.top_info_type_id
