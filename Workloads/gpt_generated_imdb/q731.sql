WITH cast_agg AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count,
           COUNT(DISTINCT ct.kind) AS distinct_company_type_count,
           SUM(CASE WHEN ct.kind = 'production' THEN 1 ELSE 0 END) AS production_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
rating_agg AS (
    SELECT mi.movie_id,
           CAST(mi.info AS DOUBLE) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
)
SELECT
    kt.kind AS kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(COALESCE(ca.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(co.company_count, 0)) AS avg_companies_per_movie,
    AVG(COALESCE(co.distinct_company_type_count, 0)) AS avg_distinct_company_types_per_movie,
    AVG(COALESCE(co.production_company_count, 0)) AS avg_production_companies_per_movie,
    AVG(COALESCE(ka.keyword_count, 0)) AS avg_keywords_per_movie,
    AVG(ra.rating) AS avg_rating
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_agg ca ON t.id = ca.movie_id
LEFT JOIN company_agg co ON t.id = co.movie_id
LEFT JOIN keyword_agg ka ON t.id = ka.movie_id
LEFT JOIN rating_agg ra ON t.id = ra.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY kt.kind, t.production_year
