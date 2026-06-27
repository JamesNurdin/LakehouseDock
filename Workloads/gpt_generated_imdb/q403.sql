WITH role_counts AS (
    SELECT
        t.production_year,
        cn.name AS character_name,
        COUNT(*) AS appearance_count,
        COUNT(DISTINCT t.id) AS movie_count
    FROM cast_info ci
    JOIN title t
        ON ci.movie_id = t.id
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    WHERE t.kind_id = 1
      AND t.production_year IS NOT NULL
    GROUP BY t.production_year, cn.name
),
ranked_roles AS (
    SELECT
        rc.production_year,
        rc.character_name,
        rc.appearance_count,
        rc.movie_count,
        ROW_NUMBER() OVER (
            PARTITION BY rc.production_year
            ORDER BY rc.appearance_count DESC, rc.movie_count DESC
        ) AS rank_in_year
    FROM role_counts rc
)
SELECT
    production_year,
    character_name,
    appearance_count,
    movie_count,
    rank_in_year
FROM ranked_roles
WHERE rank_in_year <= 5
ORDER BY production_year, rank_in_year
