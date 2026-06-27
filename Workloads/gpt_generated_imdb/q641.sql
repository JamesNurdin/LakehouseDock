WITH actor_summary AS (
    SELECT
        n.id AS person_id,
        n.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    GROUP BY n.id, n.name
),
actor_kind_counts AS (
    SELECT
        n.id AS person_id,
        n.name AS actor_name,
        kt.kind AS kind,
        COUNT(DISTINCT ci.movie_id) AS kind_movie_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    GROUP BY n.id, n.name, kt.kind
),
actor_most_common_kind AS (
    SELECT
        person_id,
        actor_name,
        kind AS most_common_kind,
        kind_movie_count,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY kind_movie_count DESC) AS rn
    FROM actor_kind_counts
)
SELECT
    asu.person_id,
    asu.actor_name,
    asu.movie_count,
    asu.avg_production_year,
    amck.most_common_kind,
    amck.kind_movie_count AS movies_in_most_common_kind
FROM actor_summary AS asu
JOIN actor_most_common_kind AS amck
    ON asu.person_id = amck.person_id
WHERE amck.rn = 1
ORDER BY asu.movie_count DESC
LIMIT 10
