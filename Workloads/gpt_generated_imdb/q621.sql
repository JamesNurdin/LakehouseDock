WITH movie_counts AS (
    SELECT ci.person_id,
           COUNT(DISTINCT ci.movie_id) AS movie_cnt
    FROM cast_info ci
    GROUP BY ci.person_id
),
aka_counts AS (
    SELECT an.person_id,
           COUNT(*) AS aka_cnt
    FROM aka_name an
    GROUP BY an.person_id
),
info_counts AS (
    SELECT pi.person_id,
           COUNT(*) AS info_cnt
    FROM person_info pi
    GROUP BY pi.person_id
),
birthdate_persons AS (
    SELECT DISTINCT pi.person_id
    FROM person_info pi
    JOIN info_type it ON pi.info_type_id = it.id
    WHERE it.info = 'birth date'
)
SELECT
    n.gender,
    COUNT(DISTINCT n.id) AS person_cnt,
    SUM(COALESCE(mc.movie_cnt, 0)) AS total_movies,
    AVG(COALESCE(mc.movie_cnt, 0)) AS avg_movies_per_person,
    SUM(COALESCE(ac.aka_cnt, 0)) AS total_alternate_names,
    SUM(COALESCE(ic.info_cnt, 0)) AS total_info_entries,
    COUNT(DISTINCT bh.person_id) AS persons_with_birthdate
FROM name n
LEFT JOIN movie_counts mc ON mc.person_id = n.id
LEFT JOIN aka_counts ac ON ac.person_id = n.id
LEFT JOIN info_counts ic ON ic.person_id = n.id
LEFT JOIN birthdate_persons bh ON bh.person_id = n.id
GROUP BY n.gender
ORDER BY total_movies DESC
