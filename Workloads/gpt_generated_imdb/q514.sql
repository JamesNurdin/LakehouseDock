WITH movie_aggregates AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        COUNT(DISTINCT mk.keyword_id) AS kw_cnt,
        COUNT(DISTINCT mc.company_id) AS comp_cnt
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    kind,
    production_year,
    COUNT(*) AS movies_in_group,
    AVG(cast_cnt) AS avg_cast_per_movie,
    AVG(kw_cnt) AS avg_keywords_per_movie,
    AVG(comp_cnt) AS avg_companies_per_movie
FROM movie_aggregates
GROUP BY kind, production_year
ORDER BY avg_cast_per_movie DESC
LIMIT 10
