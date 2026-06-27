WITH
    cast_sizes AS (
        SELECT ci.movie_id,
               COUNT(DISTINCT ci.person_id) AS cast_size
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    movie_metrics AS (
        SELECT mii.movie_id,
               MAX(CASE WHEN it.info = 'rating' THEN mii.note END) AS rating,
               MAX(CASE WHEN it.info = 'runtime' THEN mii.note END) AS runtime
        FROM movie_info_idx mii
        JOIN info_type it ON mii.info_type_id = it.id
        GROUP BY mii.movie_id
    ),
    movie_keywords AS (
        SELECT mk.movie_id,
               k.keyword
        FROM movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    ),
    company_counts AS (
        SELECT mc.movie_id,
               COUNT(DISTINCT cn.id) AS prod_company_count
        FROM movie_companies mc
        JOIN company_type ct ON mc.company_type_id = ct.id
        JOIN company_name cn ON mc.company_id = cn.id
        WHERE ct.kind = 'production companies'
        GROUP BY mc.movie_id
    )
SELECT
    t.production_year AS year,
    kt.kind AS kind,
    mk.keyword,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(mm.rating) AS avg_rating,
    AVG(mm.runtime) AS avg_runtime,
    AVG(cs.cast_size) AS avg_cast_size,
    AVG(cc.prod_company_count) AS avg_prod_companies
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
JOIN movie_keywords mk ON t.id = mk.movie_id
LEFT JOIN movie_metrics mm ON t.id = mm.movie_id
LEFT JOIN cast_sizes cs ON t.id = cs.movie_id
LEFT JOIN company_counts cc ON t.id = cc.movie_id
WHERE t.production_year IS NOT NULL
  AND t.production_year >= 2000
GROUP BY
    t.production_year,
    kt.kind,
    mk.keyword
ORDER BY
    t.production_year,
    kt.kind,
    movie_count DESC
LIMIT 100
