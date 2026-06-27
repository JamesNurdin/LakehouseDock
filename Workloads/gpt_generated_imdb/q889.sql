/*
  Analytic query: count of movies released from the year 2000 onward,
  grouped by the producing company and its company‑type, together with the
  average production year of those movies.
*/
WITH recent_titles AS (
    SELECT
        id,
        production_year
    FROM title
    WHERE production_year >= 2000
)
SELECT
    cn.name          AS company_name,
    ct.kind          AS company_type,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(t.production_year)      AS avg_production_year
FROM movie_companies mc
JOIN recent_titles t
    ON mc.movie_id = t.id
JOIN company_name cn
    ON mc.company_id = cn.id
JOIN company_type ct
    ON mc.company_type_id = ct.id
GROUP BY cn.name, ct.kind
ORDER BY movie_count DESC
LIMIT 20
