WITH
    cast_counts AS (
        SELECT ci.movie_id AS movie_id,
               COUNT(*) AS cast_cnt
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    keyword_counts AS (
        SELECT mk.movie_id AS movie_id,
               COUNT(*) AS kw_cnt
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    ),
    company_counts AS (
        SELECT mc.movie_id AS movie_id,
               COUNT(*) AS comp_cnt
        FROM movie_companies mc
        GROUP BY mc.movie_id
    ),
    movie_stats AS (
        SELECT
            t.id AS movie_id,
            kt.kind AS kind,
            COALESCE(cc.cast_cnt, 0) AS cast_cnt,
            COALESCE(kc.kw_cnt, 0) AS kw_cnt,
            COALESCE(compc.comp_cnt, 0) AS comp_cnt
        FROM title t
        JOIN kind_type kt ON t.kind_id = kt.id
        LEFT JOIN cast_counts cc ON cc.movie_id = t.id
        LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
        LEFT JOIN company_counts compc ON compc.movie_id = t.id
        WHERE t.production_year >= 2000
    )
SELECT
    kind,
    COUNT(*) AS movie_count,
    AVG(cast_cnt) AS avg_cast_per_movie,
    AVG(kw_cnt) AS avg_keywords_per_movie,
    AVG(comp_cnt) AS avg_companies_per_movie
FROM movie_stats
GROUP BY kind
ORDER BY movie_count DESC
