WITH movie_budget AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
),
company_movies AS (
    SELECT
        mc.company_id,
        mc.company_type_id,
        t.id AS movie_id,
        t.production_year,
        mb.budget
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_budget mb ON t.id = mb.movie_id
    WHERE mc.company_type_id = 1
      AND kt.kind = 'movie'
      AND t.production_year >= 2000
)
SELECT
    cm.company_id,
    cm.company_type_id,
    COUNT(DISTINCT cm.movie_id) AS total_movies,
    AVG(cm.budget) AS avg_budget,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    (COUNT(ci.person_id) * 1.0 / COUNT(DISTINCT cm.movie_id)) AS avg_cast_per_movie
FROM company_movies cm
LEFT JOIN cast_info ci ON ci.movie_id = cm.movie_id
LEFT JOIN name n ON ci.person_id = n.id
GROUP BY cm.company_id, cm.company_type_id
ORDER BY total_movies DESC
LIMIT 10
