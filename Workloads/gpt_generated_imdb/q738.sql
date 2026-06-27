WITH movie_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id
),
movie_budget AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
)
SELECT
    t.production_year,
    kt.kind AS kind,
    COUNT(*) AS movie_count,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    AVG(mc.company_count) AS avg_company_per_movie,
    AVG(mb.budget) AS avg_budget
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_counts mc ON mc.movie_id = t.id
LEFT JOIN movie_budget mb ON mb.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year, kt.kind
