WITH keyword_counts AS (
    SELECT
        kt.kind,
        kw.keyword,
        COUNT(*) AS kw_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY kt.kind, kw.keyword
),
keyword_rank AS (
    SELECT
        kind,
        keyword,
        kw_count,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY kw_count DESC) AS rn
    FROM keyword_counts
),
top_keywords AS (
    SELECT
        kind,
        ARRAY_AGG(keyword ORDER BY rn) AS top_keywords
    FROM keyword_rank
    WHERE rn <= 3
    GROUP BY kind
),
kind_stats AS (
    SELECT
        kt.kind,
        COUNT(t.id) AS movie_count,
        AVG(t.production_year) AS avg_production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    GROUP BY kt.kind
)
SELECT
    ks.kind,
    ks.movie_count,
    ks.avg_production_year,
    tk.top_keywords
FROM kind_stats ks
LEFT JOIN top_keywords tk ON ks.kind = tk.kind
ORDER BY ks.movie_count DESC
