WITH 
    cast_counts AS (
        SELECT 
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS cast_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    keyword_counts AS (
        SELECT 
            mk.movie_id,
            COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    ),
    company_counts AS (
        SELECT 
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM movie_companies mc
        GROUP BY mc.movie_id
    ),
    budget_per_movie AS (
        SELECT 
            mi.movie_id,
            TRY_CAST(mi.info AS DOUBLE) AS budget
        FROM movie_info mi
        JOIN info_type it
            ON it.id = mi.info_type_id
        WHERE it.info = 'budget'
          AND mi.info IS NOT NULL
    )
SELECT 
    t.production_year,
    COUNT(t.id) AS movie_count,
    AVG(cast_counts.cast_count) AS avg_cast_per_movie,
    AVG(keyword_counts.keyword_count) AS avg_keywords_per_movie,
    AVG(company_counts.company_count) AS avg_companies_per_movie,
    AVG(budget_per_movie.budget) AS avg_budget
FROM title t
LEFT JOIN cast_counts
    ON cast_counts.movie_id = t.id
LEFT JOIN keyword_counts
    ON keyword_counts.movie_id = t.id
LEFT JOIN company_counts
    ON company_counts.movie_id = t.id
LEFT JOIN budget_per_movie
    ON budget_per_movie.movie_id = t.id
WHERE t.production_year IS NOT NULL
  AND t.production_year BETWEEN 2000 AND 2020
GROUP BY t.production_year
ORDER BY t.production_year
