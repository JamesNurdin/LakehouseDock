WITH company_type_producer_counts AS (
    SELECT
        ct.kind AS company_type,
        COUNT(mc.id) AS total_entries,
        COUNT(DISTINCT mc.movie_id) AS distinct_movies,
        COUNT(DISTINCT mc.company_id) AS distinct_companies
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE lower(mc.note) LIKE '%producer%'
    GROUP BY ct.kind
)
SELECT
    company_type,
    total_entries,
    distinct_movies,
    distinct_companies,
    ROUND(total_entries * 1.0 / distinct_movies, 2) AS avg_entries_per_movie
FROM company_type_producer_counts
ORDER BY total_entries DESC
