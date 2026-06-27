WITH cast_stats AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(*) AS role_count,
        COUNT(DISTINCT cn.id) AS character_count
    FROM cast_info ci
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.movie_id
),
movie_financials AS (
    SELECT
        mi.movie_id,
        MAX(CASE WHEN it.info = 'budget' THEN mi.info END) AS budget,
        MAX(CASE WHEN it.info = 'gross' THEN mi.info END) AS gross
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT
    t.title,
    t.production_year,
    cs.cast_count,
    cs.role_count,
    CAST(cs.role_count AS double) / cs.cast_count AS avg_roles_per_cast,
    cs.character_count,
    CAST(cs.character_count AS double) / cs.cast_count AS avg_characters_per_cast,
    mf.budget,
    mf.gross
FROM title t
LEFT JOIN cast_stats cs ON cs.movie_id = t.id
LEFT JOIN movie_financials mf ON mf.movie_id = t.id
WHERE cs.cast_count IS NOT NULL
ORDER BY cs.cast_count DESC, t.production_year
LIMIT 10
