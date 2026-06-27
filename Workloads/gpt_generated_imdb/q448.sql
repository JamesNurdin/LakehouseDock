WITH actor_counts AS (
    SELECT
        ci.movie_id AS movie_id,
        COUNT(DISTINCT n.id) AS num_actors
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id AS movie_id,
        COUNT(DISTINCT k.id) AS num_keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
rating_agg AS (
    SELECT
        mi.movie_id AS movie_id,
        AVG(CAST(mi.info AS double)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind,
    COALESCE(ac.num_actors, 0) AS num_actors,
    COALESCE(kc.num_keywords, 0) AS num_keywords,
    COALESCE(ra.avg_rating, 0) AS avg_rating
FROM title t
LEFT JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN actor_counts ac ON ac.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN rating_agg ra ON ra.movie_id = t.id
WHERE t.production_year IS NOT NULL
ORDER BY num_actors DESC, avg_rating DESC
LIMIT 100
