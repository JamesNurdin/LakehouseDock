WITH movie_cast AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_cnt
    FROM cast_info
    GROUP BY movie_id
),
movie_keywords AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS kw_cnt
    FROM movie_keyword
    GROUP BY movie_id
),
movie_companies AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS comp_cnt,
        COUNT(DISTINCT ct.kind) AS comp_type_cnt
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT
    t.production_year,
    kt.kind AS movie_kind,
    COUNT(DISTINCT t.id) AS total_movies,
    SUM(COALESCE(mc.cast_cnt, 0)) AS total_cast_members,
    SUM(COALESCE(mk.kw_cnt, 0)) AS total_keywords,
    SUM(COALESCE(mco.comp_cnt, 0)) AS total_companies,
    AVG(COALESCE(mc.cast_cnt, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(mk.kw_cnt, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(mco.comp_cnt, 0)) AS avg_companies_per_movie,
    AVG(COALESCE(mco.comp_type_cnt, 0)) AS avg_company_types_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_cast mc ON t.id = mc.movie_id
LEFT JOIN movie_keywords mk ON t.id = mk.movie_id
LEFT JOIN movie_companies mco ON t.id = mco.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, total_movies DESC
LIMIT 100
