WITH movie_info_agg AS (
    SELECT
        movie_id,
        avg(length(info)) AS avg_info_length,
        count(*) AS info_count
    FROM movie_info
    GROUP BY movie_id
)
SELECT
    company_type.kind AS company_type,
    count(DISTINCT movie_companies.movie_id) AS movie_count,
    count(DISTINCT movie_companies.company_id) AS distinct_company_count,
    avg(title.production_year) AS avg_production_year,
    avg(movie_info_agg.avg_info_length) AS avg_info_length_per_movie,
    sum(movie_info_agg.info_count) AS total_info_entries
FROM movie_companies
JOIN title
    ON movie_companies.movie_id = title.id
JOIN company_type
    ON movie_companies.company_type_id = company_type.id
LEFT JOIN movie_info_agg
    ON title.id = movie_info_agg.movie_id
WHERE title.production_year IS NOT NULL
GROUP BY company_type.kind
ORDER BY movie_count DESC
LIMIT 10
