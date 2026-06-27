WITH actor_movies AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        kt.kind AS kind_name
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
),
actor_budget_gross AS (
    SELECT
        am.actor_id,
        SUM(CASE WHEN it.info = 'budget' THEN TRY_CAST(mi.info AS double) ELSE 0 END) AS total_budget,
        SUM(CASE WHEN it.info = 'gross'  THEN TRY_CAST(mi.info AS double) ELSE 0 END) AS total_gross
    FROM actor_movies am
    JOIN movie_info mi ON mi.movie_id = am.movie_id
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY am.actor_id
),
actor_keyword_counts AS (
    SELECT
        am.actor_id,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keywords
    FROM actor_movies am
    JOIN movie_keyword mk ON mk.movie_id = am.movie_id
    GROUP BY am.actor_id
),
actor_role_counts AS (
    SELECT
        ci.person_id AS actor_id,
        cn.name AS role_name,
        COUNT(*) AS role_count
    FROM cast_info ci
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.person_id, cn.name
),
actor_top_role AS (
    SELECT
        r.actor_id,
        r.role_name,
        r.role_count,
        ROW_NUMBER() OVER (PARTITION BY r.actor_id ORDER BY r.role_count DESC) AS rn
    FROM actor_role_counts r
)
SELECT
    n.id AS actor_id,
    n.name AS actor_name,
    COUNT(DISTINCT am.movie_id) AS total_movies,
    COALESCE(abg.total_budget, 0) AS total_budget,
    COALESCE(abg.total_gross, 0) AS total_gross,
    COALESCE(akc.distinct_keywords, 0) AS distinct_keywords,
    tr.role_name AS most_frequent_role,
    tr.role_count AS most_frequent_role_count
FROM name n
LEFT JOIN actor_movies am ON n.id = am.actor_id
LEFT JOIN actor_budget_gross abg ON n.id = abg.actor_id
LEFT JOIN actor_keyword_counts akc ON n.id = akc.actor_id
LEFT JOIN actor_top_role tr ON n.id = tr.actor_id AND tr.rn = 1
WHERE n.gender = 'M'
GROUP BY
    n.id,
    n.name,
    COALESCE(abg.total_budget, 0),
    COALESCE(abg.total_gross, 0),
    COALESCE(akc.distinct_keywords, 0),
    tr.role_name,
    tr.role_count
ORDER BY total_movies DESC
LIMIT 100
