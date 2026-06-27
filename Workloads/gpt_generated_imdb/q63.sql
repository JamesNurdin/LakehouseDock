WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        COUNT(DISTINCT mc.company_id) AS comp_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS movie_count,
    AVG(cast_cnt) AS avg_cast_per_movie,
    AVG(comp_cnt) AS avg_companies_per_movie
FROM movie_stats
WHERE production_year >= 2000
GROUP BY production_year, kind
ORDER BY production_year DESC, kind
