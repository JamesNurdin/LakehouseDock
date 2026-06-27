WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast,
        COUNT(DISTINCT cn.id) AS distinct_roles
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
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
    t.title,
    t.production_year,
    kt.kind,
    COALESCE(cc.total_cast, 0) AS total_cast,
    COALESCE(cc.male_cast, 0) AS male_cast,
    COALESCE(cc.female_cast, 0) AS female_cast,
    COALESCE(cc.distinct_roles, 0) AS distinct_roles,
    COALESCE(compc.company_count, 0) AS company_count,
    COALESCE(kwc.keyword_count, 0) AS keyword_count,
    COALESCE(ic.info_type_count, 0) AS info_type_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN company_counts compc ON t.id = compc.movie_id
LEFT JOIN keyword_counts kwc ON t.id = kwc.movie_id
LEFT JOIN info_counts ic ON t.id = ic.movie_id
ORDER BY total_cast DESC
LIMIT 10
