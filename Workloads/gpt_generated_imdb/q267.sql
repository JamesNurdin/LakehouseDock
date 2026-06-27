WITH movie_kind AS (
    SELECT
        title.id AS movie_id,
        title.production_year,
        kind_type.kind AS movie_kind
    FROM title
    JOIN kind_type ON title.kind_id = kind_type.id
),
movie_cast AS (
    SELECT
        cast_info.movie_id,
        COUNT(DISTINCT cast_info.person_id) AS cast_cnt
    FROM cast_info
    GROUP BY cast_info.movie_id
),
movie_keyword_counts AS (
    SELECT
        movie_keyword.movie_id,
        COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_cnt
    FROM movie_keyword
    GROUP BY movie_keyword.movie_id
),
movie_company_type AS (
    SELECT DISTINCT
        movie_companies.movie_id,
        company_type.kind AS company_type_kind
    FROM movie_companies
    JOIN company_type ON movie_companies.company_type_id = company_type.id
)
SELECT
    mk.movie_kind,
    mct.company_type_kind,
    COUNT(DISTINCT mk.movie_id) AS num_movies,
    AVG(mk.production_year) AS avg_production_year,
    SUM(COALESCE(mc.cast_cnt, 0)) AS total_cast_members,
    AVG(COALESCE(mc.cast_cnt, 0)) AS avg_cast_per_movie,
    SUM(COALESCE(mkc.keyword_cnt, 0)) AS total_keywords,
    AVG(COALESCE(mkc.keyword_cnt, 0)) AS avg_keywords_per_movie
FROM movie_company_type mct
JOIN movie_kind mk ON mct.movie_id = mk.movie_id
LEFT JOIN movie_cast mc ON mk.movie_id = mc.movie_id
LEFT JOIN movie_keyword_counts mkc ON mk.movie_id = mkc.movie_id
WHERE mk.production_year >= 2000
GROUP BY mk.movie_kind, mct.company_type_kind
ORDER BY num_movies DESC
LIMIT 20
