WITH char_counts AS (
    SELECT
        t.production_year,
        cn.name AS character_name,
        COUNT(*) AS appearance_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, cn.name
),
ranked_chars AS (
    SELECT
        production_year,
        character_name,
        appearance_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY appearance_count DESC) AS rn
    FROM char_counts
)
SELECT
    production_year,
    character_name,
    appearance_count
FROM ranked_chars
WHERE rn <= 3
ORDER BY production_year, appearance_count DESC
