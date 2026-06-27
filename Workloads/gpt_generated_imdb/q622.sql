WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        t.title,
        kt.kind,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_cnt,
        COUNT(DISTINCT mc.company_id) AS company_cnt,
        COUNT(DISTINCT kw.keyword) AS keyword_cnt
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN keyword kw
        ON mk.keyword_id = kw.id
    GROUP BY
        t.id,
        t.title,
        kt.kind,
        t.production_year
),
ranked_movies AS (
    SELECT
        kind,
        title,
        production_year,
        cast_cnt,
        company_cnt,
        keyword_cnt,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY cast_cnt DESC) AS rank_in_kind
    FROM movie_metrics
    WHERE production_year >= 2000
)
SELECT
    kind,
    title,
    production_year,
    cast_cnt,
    company_cnt,
    keyword_cnt,
    rank_in_kind
FROM ranked_movies
WHERE rank_in_kind <= 5
ORDER BY kind, rank_in_kind
