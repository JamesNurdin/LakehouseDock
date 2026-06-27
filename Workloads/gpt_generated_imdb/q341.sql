WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.kind
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
    WHERE k.kind = 'movie'
),
cast_agg AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT ci.person_role_id) AS character_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
rating_agg AS (
    SELECT
        mi.movie_id,
        AVG(CAST(mi.info AS double)) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
)
SELECT
    m.title,
    m.production_year,
    m.kind,
    COALESCE(ca.cast_count, 0) AS cast_count,
    COALESCE(ca.character_count, 0) AS character_count,
    COALESCE(coa.production_company_count, 0) AS production_company_count,
    COALESCE(ka.keyword_count, 0) AS keyword_count,
    r.rating
FROM movies m
LEFT JOIN cast_agg ca   ON m.movie_id = ca.movie_id
LEFT JOIN company_agg coa ON m.movie_id = coa.movie_id
LEFT JOIN keyword_agg ka  ON m.movie_id = ka.movie_id
LEFT JOIN rating_agg r    ON m.movie_id = r.movie_id
WHERE r.rating IS NOT NULL
ORDER BY r.rating DESC, ca.cast_count DESC
LIMIT 20
