WITH title_cast_counts AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    GROUP BY
        t.id,
        t.title,
        t.production_year,
        kt.kind
),
title_keyword_counts AS (
    SELECT
        t.id AS title_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    GROUP BY t.id
)
SELECT
    c.kind,
    c.production_year,
    COUNT(*) AS num_titles,
    AVG(c.cast_count) AS avg_cast_per_title,
    AVG(COALESCE(k.keyword_count, 0)) AS avg_keywords_per_title
FROM title_cast_counts c
LEFT JOIN title_keyword_counts k
    ON c.title_id = k.title_id
GROUP BY
    c.kind,
    c.production_year
ORDER BY
    c.kind,
    c.production_year
