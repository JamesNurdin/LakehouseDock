WITH
    title_info AS (
        SELECT
            t.id,
            t.title,
            t.production_year,
            kt.kind AS genre
        FROM title t
        JOIN kind_type kt ON t.kind_id = kt.id
    ),
    cast_counts AS (
        SELECT
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS cast_count,
            COUNT(DISTINCT ci.person_role_id) AS character_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    keyword_counts AS (
        SELECT
            mk.movie_id,
            COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    ),
    production_company_counts AS (
        SELECT
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS production_company_count
        FROM movie_companies mc
        JOIN company_type ct ON mc.company_type_id = ct.id
        WHERE lower(ct.kind) = 'production'
        GROUP BY mc.movie_id
    )
SELECT
    ti.title,
    ti.production_year,
    ti.genre,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(cc.character_count, 0) AS character_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(pc.production_company_count, 0) AS production_company_count
FROM title_info ti
LEFT JOIN cast_counts cc ON ti.id = cc.movie_id
LEFT JOIN keyword_counts kc ON ti.id = kc.movie_id
LEFT JOIN production_company_counts pc ON ti.id = pc.movie_id
ORDER BY cast_count DESC
LIMIT 10
