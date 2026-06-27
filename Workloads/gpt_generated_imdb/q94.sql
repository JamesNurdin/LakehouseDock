WITH movie_cast AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast,
        COUNT(DISTINCT ci.person_role_id) AS distinct_roles
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS distinct_companies,
        COUNT(DISTINCT mc.company_type_id) AS distinct_company_types
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_info_agg AS (
    SELECT
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS distinct_info_types
    FROM movie_info mi
    GROUP BY mi.movie_id
),
actor_year AS (
    SELECT
        t.production_year,
        COUNT(DISTINCT n.id) AS distinct_actors
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year
),
character_year AS (
    SELECT
        t.production_year,
        COUNT(DISTINCT cn.id) AS distinct_characters
    FROM cast_info ci
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year
),
movie_year AS (
    SELECT
        t.production_year,
        COUNT(DISTINCT t.id) AS movie_count,
        SUM(COALESCE(mc.distinct_companies, 0)) AS total_companies,
        SUM(COALESCE(mi.distinct_info_types, 0)) AS total_info_types,
        SUM(COALESCE(ca.distinct_cast, 0)) AS total_cast,
        AVG(COALESCE(ca.distinct_cast, 0)) AS avg_cast_per_movie,
        MAX(COALESCE(ca.distinct_cast, 0)) AS max_cast_per_movie,
        MIN(COALESCE(ca.distinct_cast, 0)) AS min_cast_per_movie
    FROM title t
    LEFT JOIN movie_cast ca ON ca.movie_id = t.id
    LEFT JOIN movie_company mc ON mc.movie_id = t.id
    LEFT JOIN movie_info_agg mi ON mi.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year
)
SELECT
    my.production_year,
    my.movie_count,
    my.total_companies,
    my.total_info_types,
    my.total_cast,
    my.avg_cast_per_movie,
    my.max_cast_per_movie,
    my.min_cast_per_movie,
    ay.distinct_actors,
    cy.distinct_characters
FROM movie_year my
LEFT JOIN actor_year ay ON ay.production_year = my.production_year
LEFT JOIN character_year cy ON cy.production_year = my.production_year
ORDER BY my.production_year
