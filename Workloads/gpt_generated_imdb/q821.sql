WITH yearly_type_stats AS (
    SELECT
        t.production_year,
        ct.kind,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT cn.id) AS distinct_company_count,
        CAST(COUNT(mi.id) AS double) / NULLIF(COUNT(DISTINCT t.id), 0) AS avg_info_per_movie
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.production_year, ct.kind
)
SELECT
    production_year,
    kind,
    movie_count,
    distinct_company_count,
    avg_info_per_movie,
    RANK() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rank_by_movie_count
FROM yearly_type_stats
ORDER BY production_year DESC, rank_by_movie_count
