WITH company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
info_counts AS (
    SELECT mi.movie_id,
           COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM movie_info mi
    GROUP BY mi.movie_id
),
movie_aggregates AS (
    SELECT
        t.production_year,
        kt.kind,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(COALESCE(cc.company_count, 0)) AS avg_companies_per_movie,
        AVG(COALESCE(ic.info_type_count, 0)) AS avg_info_types_per_movie
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN company_counts cc ON cc.movie_id = t.id
    LEFT JOIN info_counts ic ON ic.movie_id = t.id
    WHERE t.production_year IS NOT NULL
      AND t.production_year >= 2000
    GROUP BY t.production_year, kt.kind
)
SELECT
    ma.production_year,
    ma.kind,
    ma.movie_count,
    ma.avg_companies_per_movie,
    ma.avg_info_types_per_movie,
    ROW_NUMBER() OVER (PARTITION BY ma.production_year ORDER BY ma.movie_count DESC) AS rank_by_movie_count
FROM movie_aggregates ma
ORDER BY ma.production_year, rank_by_movie_count
