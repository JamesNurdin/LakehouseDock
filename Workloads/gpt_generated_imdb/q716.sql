WITH keyword_stats AS (
    SELECT
        k.keyword,
        kt.kind,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(t.production_year) AS avg_production_year
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
    GROUP BY k.keyword, kt.kind
),
ranked_keywords AS (
    SELECT
        kind,
        keyword,
        movie_count,
        avg_production_year,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY movie_count DESC) AS rn
    FROM keyword_stats
    WHERE movie_count > 5
)
SELECT
    kind,
    keyword,
    movie_count,
    avg_production_year,
    rn
FROM ranked_keywords
WHERE rn <= 5
ORDER BY kind, rn
