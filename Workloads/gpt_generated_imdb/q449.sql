WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count,
           COUNT(DISTINCT cn.country_code) AS distinct_company_countries
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
info_counts AS (
    SELECT mi.movie_id,
           COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT
    t.id AS title_id,
    t.title,
    t.production_year,
    kt.kind,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(compc.company_count, 0) AS company_count,
    COALESCE(compc.distinct_company_countries, 0) AS distinct_company_countries,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(ic.info_type_count, 0) AS info_type_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN company_counts compc ON t.id = compc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN info_counts ic ON t.id = ic.movie_id
WHERE kt.kind = 'movie'
  AND t.production_year >= 2000
ORDER BY cast_count DESC, title
LIMIT 10
