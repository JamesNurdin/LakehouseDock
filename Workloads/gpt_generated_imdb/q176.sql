WITH movie_base AS (
    SELECT
        t.id AS movie_id,
        t.production_year AS prod_year,
        kt.kind AS kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
),
movie_cast_counts AS (
    SELECT
        mb.movie_id,
        mb.kind,
        mb.prod_year,
        COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM movie_base mb
    JOIN cast_info ci ON ci.movie_id = mb.movie_id
    GROUP BY mb.movie_id, mb.kind, mb.prod_year
),
movie_stats AS (
    SELECT
        kind,
        prod_year,
        COUNT(*) AS total_movies,
        AVG(cast_cnt) AS avg_cast_per_movie
    FROM movie_cast_counts
    GROUP BY kind, prod_year
),
keyword_counts AS (
    SELECT
        kt.kind AS kind,
        t.production_year AS prod_year,
        k.keyword AS keyword,
        COUNT(*) AS kw_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY kt.kind, t.production_year, k.keyword
),
top_keyword_per_year AS (
    SELECT
        kind,
        prod_year,
        keyword,
        kw_cnt,
        ROW_NUMBER() OVER (PARTITION BY kind, prod_year ORDER BY kw_cnt DESC) AS rn
    FROM keyword_counts
)
SELECT
    ms.kind,
    ms.prod_year,
    ms.total_movies,
    ms.avg_cast_per_movie,
    tk.keyword AS top_keyword,
    tk.kw_cnt AS top_keyword_count
FROM movie_stats ms
LEFT JOIN (
    SELECT kind, prod_year, keyword, kw_cnt
    FROM top_keyword_per_year
    WHERE rn = 1
) tk ON ms.kind = tk.kind AND ms.prod_year = tk.prod_year
ORDER BY ms.kind, ms.prod_year
