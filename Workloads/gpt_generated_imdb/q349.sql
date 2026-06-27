WITH
    cast_counts AS (
        SELECT
            movie_id,
            COUNT(DISTINCT person_id) AS cast_count
        FROM cast_info
        GROUP BY movie_id
    ),
    plot_counts AS (
        SELECT
            mi.movie_id,
            COUNT(*) AS plot_info_count
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'Plot'
        GROUP BY mi.movie_id
    ),
    keyword_counts AS (
        SELECT
            movie_id,
            COUNT(DISTINCT keyword_id) AS keyword_count
        FROM movie_keyword
        GROUP BY movie_id
    )
SELECT
    t.production_year,
    mk.keyword_id,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(pc.plot_info_count, 0)) AS avg_plot_info_per_movie,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keyword_per_movie
FROM title t
JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN plot_counts pc ON pc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
WHERE t.kind_id = 1
GROUP BY t.production_year, mk.keyword_id
ORDER BY t.production_year DESC, movie_count DESC
