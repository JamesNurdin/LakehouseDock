WITH actor_keyword_counts AS (
    SELECT
        k.keyword,
        n.name AS actor_name,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(CASE WHEN it.info = 'rating' THEN CAST(mi.info AS DOUBLE) END) AS avg_rating
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    WHERE kt.kind = 'movie' AND t.production_year >= 2000
    GROUP BY k.keyword, n.name
),
ranked AS (
    SELECT
        keyword,
        actor_name,
        movie_count,
        avg_rating,
        ROW_NUMBER() OVER (PARTITION BY keyword ORDER BY movie_count DESC) AS rn
    FROM actor_keyword_counts
)
SELECT
    keyword,
    actor_name,
    movie_count,
    avg_rating
FROM ranked
WHERE rn = 1
ORDER BY keyword
