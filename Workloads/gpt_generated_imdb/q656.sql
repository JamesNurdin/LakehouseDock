WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
),
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT cn.id) AS character_count
    FROM cast_info ci
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
info_counts AS (
    SELECT
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    m.kind,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(cc.character_count, 0) AS character_count,
    COALESCE(compc.company_count, 0) AS company_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(ic.info_type_count, 0) AS info_type_count
FROM movies m
LEFT JOIN cast_counts cc
    ON m.movie_id = cc.movie_id
LEFT JOIN company_counts compc
    ON m.movie_id = compc.movie_id
LEFT JOIN keyword_counts kc
    ON m.movie_id = kc.movie_id
LEFT JOIN info_counts ic
    ON m.movie_id = ic.movie_id
ORDER BY m.production_year DESC, cast_count DESC
LIMIT 100
