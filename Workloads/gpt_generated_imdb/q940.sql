WITH person_movie_counts AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT t.id) AS movie_count
    FROM
        name n
        JOIN cast_info ci ON ci.person_id = n.id
        JOIN title t ON ci.movie_id = t.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        n.id,
        n.name
),
role_counts AS (
    SELECT
        ci.person_id,
        ci.person_role_id,
        COUNT(*) AS cnt
    FROM
        cast_info ci
    GROUP BY
        ci.person_id,
        ci.person_role_id
),
person_top_character AS (
    SELECT
        rc.person_id,
        cn.name AS character_name,
        rc.cnt AS character_appearances
    FROM (
        SELECT
            person_id,
            person_role_id,
            cnt,
            ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY cnt DESC) AS rn
        FROM role_counts
    ) rc
    JOIN char_name cn ON cn.id = rc.person_role_id
    WHERE rc.rn = 1
)
SELECT
    pmc.person_id,
    pmc.person_name,
    pmc.movie_count,
    ptc.character_name,
    ptc.character_appearances,
    array_agg(DISTINCT an.name) AS aka_names
FROM
    person_movie_counts pmc
    LEFT JOIN person_top_character ptc ON ptc.person_id = pmc.person_id
    LEFT JOIN aka_name an ON an.person_id = pmc.person_id
GROUP BY
    pmc.person_id,
    pmc.person_name,
    pmc.movie_count,
    ptc.character_name,
    ptc.character_appearances
ORDER BY
    pmc.movie_count DESC,
    pmc.person_name
LIMIT 10
