WITH cast_agg AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_member_count,
        COUNT(DISTINCT ci.role_id) AS distinct_role_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN mc.company_id END) AS production_company_count,
        COUNT(DISTINCT CASE WHEN ct.kind = 'distribution' THEN mc.company_id END) AS distribution_company_count,
        COUNT(DISTINCT cn.country_code) AS distinct_company_country_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT
    t.title,
    t.production_year,
    ca.cast_member_count,
    ca.distinct_role_count,
    co.total_company_count,
    co.production_company_count,
    co.distribution_company_count,
    co.distinct_company_country_count
FROM title t
LEFT JOIN cast_agg ca ON ca.movie_id = t.id
LEFT JOIN company_agg co ON co.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY ca.cast_member_count DESC NULLS LAST
LIMIT 10
