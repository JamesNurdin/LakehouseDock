WITH cast_agg AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN cn.id END) AS production_company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
info_agg AS (
    SELECT
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT
    t.title,
    t.production_year,
    ca.cast_count,
    co.production_company_count,
    i.info_type_count,
    ROW_NUMBER() OVER (ORDER BY ca.cast_count DESC) AS rank_by_cast
FROM title t
LEFT JOIN cast_agg ca ON ca.movie_id = t.id
LEFT JOIN company_agg co ON co.movie_id = t.id
LEFT JOIN info_agg i ON i.movie_id = t.id
ORDER BY ca.cast_count DESC
LIMIT 10
