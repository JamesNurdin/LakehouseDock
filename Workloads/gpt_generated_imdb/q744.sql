WITH cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(cc.cast_cnt, 0) AS cast_cnt,
        COALESCE(kc.kw_cnt, 0) AS kw_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_counts cc ON cc.movie_id = t.id
    LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
    WHERE kt.kind = 'movie'
)
SELECT
    production_year,
    COUNT(*) AS num_movies,
    AVG(cast_cnt) AS avg_cast_per_movie,
    AVG(kw_cnt) AS avg_keywords_per_movie
FROM movie_stats
GROUP BY production_year
ORDER BY production_year
