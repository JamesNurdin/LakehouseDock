WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT ct.kind) AS company_kinds
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    COALESCE(cc.cast_count, 0) AS cast_count,
    ca.company_names,
    ca.company_kinds,
    ka.keywords
FROM title t
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN company_agg ca ON ca.movie_id = t.id
LEFT JOIN keyword_agg ka ON ka.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY cast_count DESC
LIMIT 10
