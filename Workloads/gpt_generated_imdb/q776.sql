/*
  Analytical query: For each title kind (e.g., movie, TV series) released from the year 2000 onward,
  compute the number of titles, the average rating, average runtime (minutes),
  average number of distinct cast members, and average number of distinct production companies.
  The result is ordered by average rating and limited to the top 10 kinds.
*/
WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        MAX(CASE WHEN mi.info_type_id = 101 THEN CAST(mi.info AS double) END) AS rating,
        MAX(CASE WHEN mi.info_type_id = 102 THEN CAST(mi.info AS double) END) AS runtime_minutes
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    GROUP BY
        t.id,
        t.title,
        t.production_year,
        kt.kind
)
SELECT
    kind,
    COUNT(*) AS movie_count,
    AVG(rating) AS avg_rating,
    AVG(runtime_minutes) AS avg_runtime_minutes,
    AVG(cast_count) AS avg_cast_count,
    AVG(company_count) AS avg_company_count
FROM movie_stats
WHERE production_year >= 2000
GROUP BY kind
ORDER BY avg_rating DESC
LIMIT 10
