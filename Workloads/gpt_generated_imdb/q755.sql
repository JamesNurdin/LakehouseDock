WITH movie_base AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind
    FROM title t
    LEFT JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
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

rating_budget AS (
    SELECT
        mi.movie_id,
        MAX(CASE WHEN it.info = 'rating' THEN TRY_CAST(mi.info AS DOUBLE) END) AS rating,
        MAX(CASE WHEN it.info = 'budget' THEN TRY_CAST(mi.info AS DOUBLE) END) AS budget
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
),

company_type_counts AS (
    SELECT
        mc.movie_id,
        ct.kind AS company_type,
        COUNT(*) AS cnt
    FROM movie_companies mc
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, ct.kind
),

top_company_type AS (
    SELECT
        movie_id,
        company_type
    FROM (
        SELECT
            movie_id,
            company_type,
            cnt,
            ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY cnt DESC, company_type) AS rn
        FROM company_type_counts
    )
    WHERE rn = 1
)

SELECT
    mb.title,
    mb.production_year,
    mb.kind,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(cc.character_count, 0) AS character_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    rb.rating,
    rb.budget,
    tct.company_type AS top_company_type
FROM movie_base mb
LEFT JOIN cast_counts cc
    ON cc.movie_id = mb.movie_id
LEFT JOIN keyword_counts kc
    ON kc.movie_id = mb.movie_id
LEFT JOIN rating_budget rb
    ON rb.movie_id = mb.movie_id
LEFT JOIN top_company_type tct
    ON tct.movie_id = mb.movie_id
ORDER BY cast_count DESC, title
LIMIT 100
