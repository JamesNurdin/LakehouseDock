WITH cast_agg AS (
    SELECT
        cast_info.movie_id AS movie_id,
        COUNT(*) AS cast_count,
        COUNT(DISTINCT cast_info.person_id) AS distinct_cast_members
    FROM cast_info
    GROUP BY cast_info.movie_id
),
company_agg AS (
    SELECT
        movie_companies.movie_id AS movie_id,
        COUNT(*) AS company_count,
        COUNT(DISTINCT movie_companies.company_id) AS distinct_companies
    FROM movie_companies
    GROUP BY movie_companies.movie_id
),
keyword_agg AS (
    SELECT
        movie_keyword.movie_id AS movie_id,
        COUNT(*) AS keyword_count,
        COUNT(DISTINCT movie_keyword.keyword_id) AS distinct_keywords
    FROM movie_keyword
    GROUP BY movie_keyword.movie_id
),
info_agg AS (
    SELECT
        combined.movie_id AS movie_id,
        COUNT(DISTINCT combined.info_type_id) AS total_info_type_count
    FROM (
        SELECT movie_id, info_type_id FROM movie_info
        UNION ALL
        SELECT movie_id, info_type_id FROM movie_info_idx
    ) AS combined
    GROUP BY combined.movie_id
)
SELECT
    t.title AS title,
    t.production_year AS production_year,
    kt.kind AS kind,
    COALESCE(ca.cast_count, 0) AS cast_count,
    COALESCE(ca.distinct_cast_members, 0) AS distinct_cast_members,
    COALESCE(coma.company_count, 0) AS company_count,
    COALESCE(coma.distinct_companies, 0) AS distinct_companies,
    COALESCE(ka.keyword_count, 0) AS keyword_count,
    COALESCE(ka.distinct_keywords, 0) AS distinct_keywords,
    COALESCE(ia.total_info_type_count, 0) AS total_info_type_count
FROM title AS t
JOIN kind_type AS kt
    ON t.kind_id = kt.id
LEFT JOIN cast_agg AS ca
    ON ca.movie_id = t.id
LEFT JOIN company_agg AS coma
    ON coma.movie_id = t.id
LEFT JOIN keyword_agg AS ka
    ON ka.movie_id = t.id
LEFT JOIN info_agg AS ia
    ON ia.movie_id = t.id
WHERE kt.kind = 'movie'
  AND t.production_year >= 2000
ORDER BY cast_count DESC
LIMIT 100
