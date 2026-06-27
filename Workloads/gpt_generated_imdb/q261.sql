WITH total_counts AS (
    SELECT
        k.keyword,
        COUNT(DISTINCT t.id) AS total_titles
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.production_year > 2000
    GROUP BY k.keyword
),
ranked_keywords AS (
    SELECT
        keyword,
        total_titles,
        ROW_NUMBER() OVER (ORDER BY total_titles DESC) AS rn
    FROM total_counts
),
top_keywords AS (
    SELECT keyword, total_titles
    FROM ranked_keywords
    WHERE rn <= 10
),
per_kind_counts AS (
    SELECT
        k.keyword,
        kt.kind,
        COUNT(DISTINCT t.id) AS kind_titles
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    JOIN kind_type kt ON kt.id = t.kind_id
    WHERE t.production_year > 2000
      AND k.keyword IN (SELECT keyword FROM top_keywords)
    GROUP BY k.keyword, kt.kind
)
SELECT
    tk.keyword,
    tk.total_titles,
    pkc.kind,
    pkc.kind_titles
FROM top_keywords tk
JOIN per_kind_counts pkc ON pkc.keyword = tk.keyword
ORDER BY tk.total_titles DESC, pkc.kind_titles DESC
