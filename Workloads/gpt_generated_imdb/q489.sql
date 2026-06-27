WITH actor_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS primary_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year,
        COUNT(DISTINCT cn.id) AS distinct_characters,
        ARRAY_AGG(DISTINCT cn.name) FILTER (WHERE cn.name IS NOT NULL) AS character_names
    FROM
        cast_info ci
        JOIN name n ON ci.person_id = n.id
        JOIN title t ON ci.movie_id = t.id
        JOIN kind_type kt ON t.kind_id = kt.id
        LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE
        kt.kind = 'movie'
        AND t.production_year IS NOT NULL
        AND t.production_year BETWEEN 1990 AND 2020
    GROUP BY
        n.id,
        n.name
),
aka_agg AS (
    SELECT
        an.person_id,
        ARRAY_AGG(DISTINCT an.name) FILTER (WHERE an.name IS NOT NULL) AS aka_names
    FROM aka_name an
    GROUP BY an.person_id
)
SELECT
    a.person_id,
    a.primary_name,
    a.movie_count,
    a.first_year,
    a.last_year,
    a.distinct_characters,
    a.character_names,
    ak.aka_names
FROM
    actor_stats a
    LEFT JOIN aka_agg ak ON a.person_id = ak.person_id
ORDER BY
    a.movie_count DESC,
    a.primary_name
LIMIT 10
