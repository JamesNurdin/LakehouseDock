WITH actor_movies AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        t.id AS movie_id,
        t.production_year,
        kt.kind AS kind
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
),
actor_kind_counts AS (
    SELECT
        actor_id,
        kind,
        COUNT(*) AS kind_cnt
    FROM actor_movies
    GROUP BY actor_id, kind
),
actor_most_common_kind AS (
    SELECT
        actor_id,
        kind AS most_common_kind
    FROM (
        SELECT
            actor_id,
            kind,
            kind_cnt,
            ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY kind_cnt DESC, kind) AS rn
        FROM actor_kind_counts
    ) ranked
    WHERE rn = 1
)
SELECT
    am.actor_id,
    am.actor_name,
    COUNT(DISTINCT am.movie_id) AS movie_count,
    MIN(am.production_year) AS first_year,
    MAX(am.production_year) AS last_year,
    mkc.most_common_kind
FROM actor_movies am
JOIN actor_most_common_kind mkc ON am.actor_id = mkc.actor_id
GROUP BY am.actor_id, am.actor_name, mkc.most_common_kind
ORDER BY movie_count DESC
LIMIT 10
