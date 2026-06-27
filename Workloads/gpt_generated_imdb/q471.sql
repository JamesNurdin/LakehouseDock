WITH info_counts AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_entry_count
    FROM movie_info mi
    GROUP BY mi.movie_id
),
ranked_movies AS (
    SELECT
        t.title,
        t.production_year,
        t.kind_id,
        ic.info_entry_count,
        ROW_NUMBER() OVER (ORDER BY ic.info_entry_count DESC) AS rank
    FROM info_counts ic
    JOIN title t
        ON ic.movie_id = t.id
    WHERE t.production_year >= 2000
)
SELECT
    title,
    production_year,
    kind_id,
    info_entry_count,
    rank
FROM ranked_movies
WHERE rank <= 10
ORDER BY rank
