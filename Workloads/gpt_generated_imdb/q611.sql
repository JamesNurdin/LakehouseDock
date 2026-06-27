WITH mini_bio AS (
    SELECT pi.person_id,
           COUNT(*) AS mini_bio_cnt
    FROM person_info pi
    JOIN info_type it ON pi.info_type_id = it.id
    WHERE it.info = 'mini biography'
    GROUP BY pi.person_id
)
SELECT
    n.id AS person_id,
    n.name,
    n.gender,
    COUNT(DISTINCT t.id) AS movie_count,
    COUNT(DISTINCT a.id) AS aka_name_count,
    COALESCE(mb.mini_bio_cnt, 0) AS mini_bio_count,
    AVG(ci.nr_order) AS avg_cast_order
FROM name n
LEFT JOIN cast_info ci ON ci.person_id = n.id
LEFT JOIN title t ON ci.movie_id = t.id
LEFT JOIN aka_name a ON a.person_id = n.id
LEFT JOIN mini_bio mb ON mb.person_id = n.id
WHERE t.production_year >= 2000 OR t.production_year IS NULL
GROUP BY n.id, n.name, n.gender, mb.mini_bio_cnt
ORDER BY movie_count DESC, n.name
LIMIT 100
