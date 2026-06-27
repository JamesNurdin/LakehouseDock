WITH actor_counts AS (
    SELECT
        n.id AS person_id,
        n.name,
        CAST(FLOOR(t.production_year / 10) * 10 AS INTEGER) AS decade,
        COUNT(DISTINCT t.id) AS movie_count
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
    GROUP BY n.id, n.name, CAST(FLOOR(t.production_year / 10) * 10 AS INTEGER)
)
SELECT
    decade,
    name,
    movie_count
FROM (
    SELECT
        decade,
        name,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY decade ORDER BY movie_count DESC, name) AS rn
    FROM actor_counts
) ranked
WHERE rn <= 5
ORDER BY decade, rn
