WITH keyword_stats AS (
    SELECT
        k.kind,
        kw.keyword,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(t.production_year) AS avg_year,
        AVG(mi.note) AS avg_rating
    FROM title t
    JOIN kind_type k
        ON t.kind_id = k.id
    JOIN movie_keyword mk
        ON mk.movie_id = t.id
    JOIN keyword kw
        ON mk.keyword_id = kw.id
    LEFT JOIN movie_info_idx mi
        ON mi.movie_id = t.id
        AND mi.info_type_id = 101
    GROUP BY k.kind, kw.keyword
    HAVING COUNT(DISTINCT t.id) >= 5
),
ranked_keywords AS (
    SELECT
        kind,
        keyword,
        movie_count,
        avg_year,
        avg_rating,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY movie_count DESC) AS keyword_rank
    FROM keyword_stats
)
SELECT
    kind,
    keyword,
    movie_count,
    avg_year,
    avg_rating
FROM ranked_keywords
WHERE keyword_rank <= 3
ORDER BY kind, movie_count DESC
