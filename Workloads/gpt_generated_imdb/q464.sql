WITH
    cast_agg AS (
        SELECT
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS total_cast,
            COUNT(DISTINCT ci.person_role_id) AS distinct_characters,
            SUM(CASE WHEN n.gender = 'M' THEN 1 ELSE 0 END) AS male_cast,
            SUM(CASE WHEN n.gender = 'F' THEN 1 ELSE 0 END) AS female_cast
        FROM cast_info ci
        JOIN name n ON ci.person_id = n.id
        GROUP BY ci.movie_id
    ),
    keyword_agg AS (
        SELECT
            mk.movie_id,
            COUNT(DISTINCT mk.keyword_id) AS distinct_keywords
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    ),
    company_agg AS (
        SELECT
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS distinct_companies
        FROM movie_companies mc
        GROUP BY mc.movie_id
    )
SELECT
    t.title,
    t.production_year,
    k.kind,
    COALESCE(ca.total_cast, 0) AS total_cast,
    COALESCE(ca.male_cast, 0) AS male_cast,
    COALESCE(ca.female_cast, 0) AS female_cast,
    CASE WHEN COALESCE(ca.female_cast, 0) = 0 THEN NULL
         ELSE CAST(COALESCE(ca.male_cast, 0) AS DOUBLE) / COALESCE(ca.female_cast, 0)
    END AS male_female_ratio,
    COALESCE(ca.distinct_characters, 0) AS distinct_characters,
    COALESCE(ka.distinct_keywords, 0) AS distinct_keywords,
    COALESCE(coma.distinct_companies, 0) AS distinct_companies
FROM title t
LEFT JOIN kind_type k ON t.kind_id = k.id
LEFT JOIN cast_agg ca ON ca.movie_id = t.id
LEFT JOIN keyword_agg ka ON ka.movie_id = t.id
LEFT JOIN company_agg coma ON coma.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY total_cast DESC, distinct_keywords DESC
LIMIT 20
