WITH cast_counts AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
keyword_counts AS (
    SELECT
        t.id AS title_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id
)
SELECT
    cc.kind,
    cc.production_year,
    COUNT(*) AS num_titles,
    AVG(cc.cast_count) AS avg_cast_per_title,
    AVG(kc.keyword_count) AS avg_keywords_per_title
FROM cast_counts cc
JOIN keyword_counts kc ON kc.title_id = cc.title_id
WHERE cc.production_year >= 2000
GROUP BY cc.kind, cc.production_year
ORDER BY avg_cast_per_title DESC
LIMIT 20
