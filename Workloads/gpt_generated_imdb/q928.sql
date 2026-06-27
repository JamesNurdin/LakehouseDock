WITH cast_agg AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT cn.id) AS character_count
    FROM cast_info ci
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.movie_id
),
keyword_agg AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_agg AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT ct.id) AS company_type_count
    FROM movie_companies mc
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind AS kind,
    COALESCE(ca.cast_count, 0) AS cast_count,
    COALESCE(ca.character_count, 0) AS character_count,
    COALESCE(ka.keyword_count, 0) AS keyword_count,
    COALESCE(compa.company_count, 0) AS company_count,
    COALESCE(compa.company_type_count, 0) AS company_type_count
FROM title t
LEFT JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_agg ca ON t.id = ca.movie_id
LEFT JOIN keyword_agg ka ON t.id = ka.movie_id
LEFT JOIN company_agg compa ON t.id = compa.movie_id
WHERE t.production_year >= 2000
  AND kt.kind = 'movie'
ORDER BY cast_count DESC
LIMIT 10
