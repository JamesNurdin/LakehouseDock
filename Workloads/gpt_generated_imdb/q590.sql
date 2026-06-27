WITH actor_movie_ratings AS (
    SELECT
        t.production_year AS year,
        n.id AS actor_id,
        n.name AS actor_name,
        n.gender AS actor_gender,
        kt.kind AS kind,
        t.id AS movie_id,
        CAST(mi.info AS double) AS rating
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE kt.kind = 'movie'
      AND it.info = 'rating'
      AND mi.info IS NOT NULL
),
actor_year_stats AS (
    SELECT
        year,
        actor_id,
        actor_name,
        actor_gender,
        kind,
        COUNT(DISTINCT movie_id) AS movie_count,
        AVG(rating) AS avg_rating
    FROM actor_movie_ratings
    GROUP BY year, actor_id, actor_name, actor_gender, kind
),
ranked_actors AS (
    SELECT
        year,
        actor_name,
        actor_gender,
        kind,
        movie_count,
        avg_rating,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY movie_count DESC) AS rank
    FROM actor_year_stats
)
SELECT
    year,
    actor_name,
    actor_gender,
    kind,
    movie_count,
    avg_rating,
    rank
FROM ranked_actors
WHERE rank <= 5
ORDER BY year DESC, rank
