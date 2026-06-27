WITH movie_info_counts AS (
    SELECT
        title.id AS title_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT movie_info.info_type_id) AS distinct_info_type_cnt,
        COUNT(*) AS total_info_cnt
    FROM
        title
    JOIN
        movie_info
        ON movie_info.movie_id = title.id
    WHERE
        title.production_year >= 2000
    GROUP BY
        title.id,
        title.title,
        title.production_year
)
SELECT
    title_id,
    title,
    production_year,
    distinct_info_type_cnt,
    total_info_cnt,
    RANK() OVER (ORDER BY distinct_info_type_cnt DESC, total_info_cnt DESC) AS info_type_rank
FROM
    movie_info_counts
ORDER BY
    info_type_rank
LIMIT 10
