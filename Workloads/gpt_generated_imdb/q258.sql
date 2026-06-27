WITH actor_movie_keyword_role AS (
    SELECT
        ci.person_id AS person_id,
        n.name AS actor_name,
        ci.movie_id AS movie_id,
        cn.name AS role_name,
        k.keyword AS keyword
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE kt.kind = 'movie'
),
actor_role_counts AS (
    SELECT
        person_id,
        actor_name,
        role_name,
        COUNT(*) AS role_count
    FROM actor_movie_keyword_role
    GROUP BY person_id, actor_name, role_name
),
actor_top_role AS (
    SELECT
        person_id,
        actor_name,
        role_name AS top_role,
        role_count
    FROM (
        SELECT
            person_id,
            actor_name,
            role_name,
            role_count,
            ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY role_count DESC, role_name) AS rn
        FROM actor_role_counts
    ) t
    WHERE rn = 1
),
actor_movie_stats AS (
    SELECT
        person_id,
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count,
        COUNT(DISTINCT keyword) AS distinct_keyword_count,
        AVG(keyword_per_movie) AS avg_keywords_per_movie,
        ARRAY_AGG(DISTINCT keyword) AS keywords
    FROM (
        SELECT
            person_id,
            actor_name,
            movie_id,
            keyword,
            COUNT(keyword) OVER (PARTITION BY person_id, movie_id) AS keyword_per_movie
        FROM actor_movie_keyword_role
    ) x
    GROUP BY person_id, actor_name
)
SELECT
    ams.actor_name,
    ams.movie_count,
    ams.distinct_keyword_count,
    ams.avg_keywords_per_movie,
    ARRAY_JOIN(ams.keywords, ', ') AS keyword_list,
    atr.top_role,
    atr.role_count AS top_role_count
FROM actor_movie_stats ams
JOIN actor_top_role atr ON ams.person_id = atr.person_id
WHERE ams.movie_count >= 5
ORDER BY ams.movie_count DESC
LIMIT 10
