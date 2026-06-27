WITH rating_per_movie AS (
    SELECT
        mi.movie_id,
        AVG(CAST(mi.info AS double)) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
)
SELECT
    t.production_year,
    COUNT(*) AS movie_count,
    AVG(r.rating) AS avg_rating,
    (
        SELECT COUNT(DISTINCT kw.keyword)
        FROM title t_kw
        JOIN kind_type kt_kw ON t_kw.kind_id = kt_kw.id
        JOIN movie_keyword mk_kw ON mk_kw.movie_id = t_kw.id
        JOIN keyword kw ON mk_kw.keyword_id = kw.id
        WHERE kt_kw.kind = 'movie'
          AND t_kw.production_year = t.production_year
          AND t_kw.production_year BETWEEN 2000 AND 2020
    ) AS distinct_keyword_count,
    (
        SELECT COUNT(DISTINCT cn.name)
        FROM title t_cp
        JOIN kind_type kt_cp ON t_cp.kind_id = kt_cp.id
        JOIN movie_companies mc_cp ON mc_cp.movie_id = t_cp.id
        JOIN company_type ct_cp ON mc_cp.company_type_id = ct_cp.id
        JOIN company_name cn ON mc_cp.company_id = cn.id
        WHERE kt_cp.kind = 'movie'
          AND ct_cp.kind = 'production'
          AND t_cp.production_year = t.production_year
          AND t_cp.production_year BETWEEN 2000 AND 2020
    ) AS distinct_production_company_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN rating_per_movie r ON t.id = r.movie_id
WHERE kt.kind = 'movie'
  AND t.production_year BETWEEN 2000 AND 2020
GROUP BY t.production_year
ORDER BY t.production_year
