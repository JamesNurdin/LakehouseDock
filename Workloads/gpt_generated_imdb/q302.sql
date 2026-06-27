WITH joined AS (
    SELECT
        info_type.id AS info_type_id,
        info_type.info AS info_type_name,
        movie_info.movie_id,
        movie_info.info AS info_value,
        movie_info.note
    FROM movie_info
    JOIN info_type ON movie_info.info_type_id = info_type.id
),
type_agg AS (
    SELECT
        info_type_id,
        info_type_name,
        COUNT(*) AS total_entries,
        COUNT(DISTINCT movie_id) AS distinct_movies
    FROM joined
    GROUP BY info_type_id, info_type_name
),
info_counts AS (
    SELECT
        info_type_id,
        info_type_name,
        info_value,
        COUNT(*) AS value_count
    FROM joined
    GROUP BY info_type_id, info_type_name, info_value
),
info_rank AS (
    SELECT
        info_type_id,
        info_type_name,
        info_value,
        value_count,
        ROW_NUMBER() OVER (PARTITION BY info_type_id ORDER BY value_count DESC) AS rn
    FROM info_counts
)
SELECT
    t.info_type_id,
    t.info_type_name,
    t.total_entries,
    t.distinct_movies,
    r.info_value AS top_info_value,
    r.value_count AS top_value_count
FROM type_agg t
LEFT JOIN info_rank r
    ON t.info_type_id = r.info_type_id
   AND r.rn = 1
ORDER BY t.distinct_movies DESC, t.total_entries DESC
