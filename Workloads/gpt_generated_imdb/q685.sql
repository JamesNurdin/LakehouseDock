WITH filtered_movies AS (
    SELECT
        t.id AS movie_id,
        k.keyword
    FROM title t
    JOIN kind_type kt ON kt.id = t.kind_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.production_year >= 2010
      AND kt.kind = 'movie'
),
keyword_movie_counts AS (
    SELECT
        fm.keyword,
        count(DISTINCT fm.movie_id) AS movie_count
    FROM filtered_movies fm
    GROUP BY fm.keyword
),
actor_counts AS (
    SELECT
        fm.keyword,
        n.name AS actor_name,
        count(DISTINCT fm.movie_id) AS actor_movie_count
    FROM filtered_movies fm
    JOIN cast_info ci ON ci.movie_id = fm.movie_id
    JOIN name n ON n.id = ci.person_id
    GROUP BY fm.keyword, n.name
),
ranked_actors AS (
    SELECT
        ac.keyword,
        ac.actor_name,
        ac.actor_movie_count,
        row_number() OVER (PARTITION BY ac.keyword ORDER BY ac.actor_movie_count DESC) AS actor_rank
    FROM actor_counts ac
)
SELECT
    ra.keyword,
    kmc.movie_count,
    ra.actor_name,
    ra.actor_movie_count,
    ra.actor_rank
FROM ranked_actors ra
JOIN keyword_movie_counts kmc ON kmc.keyword = ra.keyword
WHERE ra.actor_rank <= 3
ORDER BY ra.keyword, ra.actor_rank
