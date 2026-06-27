WITH title_info_counts AS (
    SELECT
        title.id AS title_id,
        title.title AS title_name,
        title.kind_id,
        title.production_year,
        COUNT(movie_info.info_type_id) AS info_type_count
    FROM title
    JOIN movie_info
        ON movie_info.movie_id = title.id
    WHERE movie_info.info IS NOT NULL
      AND title.production_year >= 2000
    GROUP BY title.id, title.title, title.kind_id, title.production_year
)
SELECT
    title_id,
    title_name,
    kind_id,
    production_year,
    info_type_count,
    ROW_NUMBER() OVER (PARTITION BY kind_id ORDER BY info_type_count DESC) AS rank_within_kind
FROM title_info_counts
WHERE info_type_count > 0
ORDER BY kind_id, rank_within_kind
LIMIT 20
