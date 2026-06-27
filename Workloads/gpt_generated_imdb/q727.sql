WITH per_movie AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        COUNT(DISTINCT kw.id) AS keyword_cnt,
        COUNT(DISTINCT mc.company_id) AS company_cnt
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    kind,
    production_year,
    COUNT(*) AS movie_count,
    AVG(cast_cnt) AS avg_cast_per_movie,
    AVG(keyword_cnt) AS avg_keywords_per_movie,
    AVG(company_cnt) AS avg_companies_per_movie
FROM per_movie
WHERE production_year >= 2000
GROUP BY kind, production_year
ORDER BY kind, production_year
