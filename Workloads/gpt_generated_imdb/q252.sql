WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.production_year AS production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE kt.kind = 'movie'
    GROUP BY t.id, t.production_year
),
keyword_movie_stats AS (
    SELECT
        mc.production_year AS production_year,
        k.keyword AS keyword,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        AVG(mc.cast_count) AS avg_cast_per_movie
    FROM movie_cast_counts mc
    JOIN movie_keyword mk ON mk.movie_id = mc.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mc.production_year, k.keyword
),
ranked_keywords AS (
    SELECT
        production_year,
        keyword,
        movie_count,
        avg_cast_per_movie,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rank
    FROM keyword_movie_stats
)
SELECT
    production_year,
    keyword,
    movie_count,
    avg_cast_per_movie,
    rank
FROM ranked_keywords
WHERE rank <= 5
ORDER BY production_year, rank
