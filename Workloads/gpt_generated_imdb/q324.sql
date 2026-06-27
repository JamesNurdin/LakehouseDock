WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_top_character AS (
    SELECT
        ci.movie_id,
        cn.name AS character_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(*) DESC) AS rn
    FROM cast_info ci
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    GROUP BY ci.movie_id, cn.name
)
SELECT
    ms.title,
    ms.production_year,
    ms.kind,
    ms.cast_count,
    ms.company_count,
    ms.keyword_count,
    tc.character_name
FROM movie_stats ms
LEFT JOIN movie_top_character tc
    ON tc.movie_id = ms.movie_id
    AND tc.rn = 1
ORDER BY ms.cast_count DESC
LIMIT 100
