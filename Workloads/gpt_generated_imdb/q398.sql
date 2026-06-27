WITH movies AS (
    SELECT t.id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT cn.id) AS company_count,
           COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN cn.id END) AS production_company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
rating_info AS (
    SELECT mi.movie_id,
           TRY_CAST(mi.info AS DOUBLE) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
)
SELECT
    m.production_year,
    m.kind,
    COUNT(*) AS movie_count,
    SUM(COALESCE(cc.cast_count, 0)) AS total_cast_members,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    SUM(COALESCE(compc.company_count, 0)) AS total_companies,
    SUM(COALESCE(compc.production_company_count, 0)) AS total_production_companies,
    SUM(COALESCE(kc.keyword_count, 0)) AS total_keywords,
    AVG(ri.rating) AS avg_rating
FROM movies m
LEFT JOIN cast_counts cc ON m.id = cc.movie_id
LEFT JOIN company_counts compc ON m.id = compc.movie_id
LEFT JOIN keyword_counts kc ON m.id = kc.movie_id
LEFT JOIN rating_info ri ON m.id = ri.movie_id
GROUP BY m.production_year, m.kind
ORDER BY m.production_year DESC, m.kind
