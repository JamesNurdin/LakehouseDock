WITH cast_agg AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN n.gender = 'M' THEN 1 ELSE 0 END) AS male_cast,
        SUM(CASE WHEN n.gender = 'F' THEN 1 ELSE 0 END) AS female_cast
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        SUM(CASE WHEN ct.kind = 'production' THEN 1 ELSE 0 END) AS production_companies,
        SUM(CASE WHEN ct.kind = 'distribution' THEN 1 ELSE 0 END) AS distribution_companies
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
info_agg AS (
    SELECT
        mi.movie_id,
        AVG(CASE WHEN it.info = 'rating' THEN try_cast(mi.info AS double) END) AS avg_rating,
        AVG(CASE WHEN it.info = 'budget' THEN try_cast(mi.info AS double) END) AS avg_budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT
    t.id AS movie_id,
    t.title,
    t.production_year,
    kt.kind AS kind,
    COALESCE(ca.total_cast, 0) AS total_cast,
    COALESCE(ca.male_cast, 0) AS male_cast,
    COALESCE(ca.female_cast, 0) AS female_cast,
    COALESCE(compa.total_companies, 0) AS total_companies,
    COALESCE(compa.production_companies, 0) AS production_companies,
    COALESCE(compa.distribution_companies, 0) AS distribution_companies,
    COALESCE(ka.total_keywords, 0) AS total_keywords,
    ROUND(COALESCE(ia.avg_rating, 0), 2) AS avg_rating,
    ROUND(COALESCE(ia.avg_budget, 0), 0) AS avg_budget
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_agg ca ON ca.movie_id = t.id
LEFT JOIN company_agg compa ON compa.movie_id = t.id
LEFT JOIN keyword_agg ka ON ka.movie_id = t.id
LEFT JOIN info_agg ia ON ia.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY total_cast DESC
LIMIT 20
