WITH actor_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT cn.id) AS distinct_characters,
        AVG(t.production_year) AS avg_production_year
    FROM
        name n
        JOIN cast_info ci ON ci.person_id = n.id
        JOIN title t ON t.id = ci.movie_id
        JOIN kind_type k ON k.id = t.kind_id
        LEFT JOIN char_name cn ON cn.id = ci.person_role_id
    WHERE
        k.kind = 'movie'
        AND t.production_year IS NOT NULL
    GROUP BY
        n.id,
        n.name
),
actor_top_company AS (
    SELECT
        as2.person_id,
        cn.name AS company_name,
        COUNT(*) AS movies_with_company,
        ROW_NUMBER() OVER (PARTITION BY as2.person_id ORDER BY COUNT(*) DESC) AS rn
    FROM
        actor_stats as2
        JOIN cast_info ci ON ci.person_id = as2.person_id
        JOIN title t ON t.id = ci.movie_id
        JOIN kind_type k ON k.id = t.kind_id
        JOIN movie_companies mc ON mc.movie_id = t.id
        JOIN company_name cn ON cn.id = mc.company_id
    WHERE
        k.kind = 'movie'
    GROUP BY
        as2.person_id,
        cn.name
)
SELECT
    as2.actor_name,
    as2.movie_count,
    as2.distinct_characters,
    ROUND(as2.avg_production_year, 1) AS avg_production_year,
    atc.company_name AS top_company,
    atc.movies_with_company AS movies_with_top_company
FROM
    actor_stats as2
    LEFT JOIN actor_top_company atc
        ON atc.person_id = as2.person_id
        AND atc.rn = 1
ORDER BY
    as2.movie_count DESC
LIMIT 10
