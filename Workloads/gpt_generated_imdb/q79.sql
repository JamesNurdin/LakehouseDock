WITH movie_stats AS (
    SELECT
        title.id               AS movie_id,
        title.kind_id          AS kind_id,
        title.production_year  AS production_year,
        COUNT(DISTINCT cast_info.person_id)      AS cast_count,
        COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count,
        COUNT(DISTINCT movie_companies.company_id) AS company_count
    FROM title
    LEFT JOIN cast_info        ON cast_info.movie_id = title.id
    LEFT JOIN movie_keyword    ON movie_keyword.movie_id = title.id
    LEFT JOIN movie_companies  ON movie_companies.movie_id = title.id
    GROUP BY title.id, title.kind_id, title.production_year
)
SELECT
    kind_type.kind                     AS kind,
    COUNT(*)                           AS movie_count,
    AVG(movie_stats.production_year)   AS avg_production_year,
    AVG(movie_stats.cast_count)        AS avg_cast_per_movie,
    AVG(movie_stats.keyword_count)    AS avg_keywords_per_movie,
    AVG(movie_stats.company_count)    AS avg_companies_per_movie
FROM movie_stats
JOIN kind_type ON movie_stats.kind_id = kind_type.id
GROUP BY kind_type.kind
ORDER BY movie_count DESC
