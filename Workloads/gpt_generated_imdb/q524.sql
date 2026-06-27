WITH company_type_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT mc.company_type_id) AS distinct_company_type_cnt
    FROM title t
    JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title
),
info_type_union AS (
    SELECT movie_id, info_type_id FROM movie_info
    UNION
    SELECT movie_id, info_type_id FROM movie_info_idx
),
info_type_counts AS (
    SELECT
        it.movie_id,
        COUNT(DISTINCT it.info_type_id) AS distinct_info_type_cnt
    FROM info_type_union it
    GROUP BY it.movie_id
)
SELECT
    ct.title,
    ct.distinct_company_type_cnt,
    COALESCE(itc.distinct_info_type_cnt, 0) AS distinct_info_type_cnt,
    (ct.distinct_company_type_cnt + COALESCE(itc.distinct_info_type_cnt, 0)) AS total_distinct_cnt
FROM company_type_counts ct
LEFT JOIN info_type_counts itc ON itc.movie_id = ct.movie_id
ORDER BY total_distinct_cnt DESC, ct.title
LIMIT 10
