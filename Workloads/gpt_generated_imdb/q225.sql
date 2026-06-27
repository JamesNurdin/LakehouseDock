WITH movie_info_counts AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_count,
        COUNT(DISTINCT mi.info_type_id) AS distinct_info_type_count,
        AVG(LENGTH(mi.info)) AS avg_info_length
    FROM movie_info mi
    GROUP BY mi.movie_id
),
movie_info_idx_counts AS (
    SELECT
        mi_idx.movie_id,
        COUNT(*) AS idx_count,
        COUNT(DISTINCT mi_idx.info_type_id) AS distinct_idx_type_count,
        AVG(LENGTH(mi_idx.info)) AS avg_idx_info_length
    FROM movie_info_idx mi_idx
    GROUP BY mi_idx.movie_id
),
aggregated AS (
    SELECT
        ct.kind AS company_type,
        cn.country_code AS company_country,
        COUNT(DISTINCT mc.movie_id) AS num_movies,
        COUNT(DISTINCT t.title) AS num_titles,
        AVG(t.production_year) AS avg_production_year,
        SUM(COALESCE(mic.info_count, 0)) AS total_info_entries,
        SUM(COALESCE(mic_idx.idx_count, 0)) AS total_info_idx_entries,
        AVG(COALESCE(mic.info_count, 0)) AS avg_info_per_movie,
        AVG(COALESCE(mic_idx.idx_count, 0)) AS avg_info_idx_per_movie
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    LEFT JOIN movie_info_counts mic ON mic.movie_id = t.id
    LEFT JOIN movie_info_idx_counts mic_idx ON mic_idx.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY ct.kind, cn.country_code
)
SELECT
    a.company_type,
    a.company_country,
    a.num_movies,
    a.num_titles,
    a.avg_production_year,
    a.total_info_entries,
    a.total_info_idx_entries,
    a.avg_info_per_movie,
    a.avg_info_idx_per_movie,
    ROW_NUMBER() OVER (ORDER BY a.num_movies DESC) AS rank_by_movies
FROM aggregated a
ORDER BY a.num_movies DESC
LIMIT 20
