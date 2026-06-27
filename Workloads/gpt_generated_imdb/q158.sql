WITH cast_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
company_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
),
keyword_counts AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
),
rating_info AS (
    SELECT
        movie_id,
        AVG(CAST(info AS double)) AS avg_rating
    FROM movie_info_idx
    WHERE info_type_id = 13
    GROUP BY movie_id
),
movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(cc.cast_count, 0) AS cast_count,
        COALESCE(compc.company_count, 0) AS company_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        r.avg_rating
    FROM title t
    LEFT JOIN cast_counts cc       ON cc.movie_id = t.id
    LEFT JOIN company_counts compc ON compc.movie_id = t.id
    LEFT JOIN keyword_counts kc    ON kc.movie_id = t.id
    LEFT JOIN rating_info r        ON r.movie_id = t.id
    WHERE t.production_year BETWEEN 2000 AND 2020
      AND t.kind_id = 1
)
SELECT
    movie_id,
    title,
    production_year,
    cast_count,
    company_count,
    keyword_count,
    avg_rating,
    (cast_count + company_count + keyword_count) AS total_entities,
    RANK() OVER (PARTITION BY production_year ORDER BY (cast_count + company_count + keyword_count) DESC) AS rank_in_year
FROM movie_stats
WHERE cast_count > 5
ORDER BY total_entities DESC
LIMIT 10
