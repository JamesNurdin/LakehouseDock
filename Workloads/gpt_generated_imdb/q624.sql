WITH movie_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    n.id AS person_id,
    n.name AS person_name,
    COUNT(DISTINCT c.movie_id) AS top_rated_movie_count,
    AVG(co.company_count) AS avg_companies_per_top_rated_movie
FROM cast_info c
JOIN name n ON c.person_id = n.id
JOIN title t ON c.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
JOIN movie_info_idx mi ON mi.movie_id = t.id
JOIN info_type it ON mi.info_type_id = it.id
JOIN movie_company_counts co ON co.movie_id = t.id
WHERE it.info = 'rating'
  AND mi.note >= 8.0
  AND kt.kind = 'movie'
GROUP BY n.id, n.name
ORDER BY top_rated_movie_count DESC
LIMIT 10
