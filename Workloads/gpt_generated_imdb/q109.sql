WITH movie_cast AS (
    -- Movies that have at least one lead actor (role_id = 1) who is listed first (nr_order = 1)
    SELECT
        t.id               AS movie_id,
        t.production_year AS production_year,
        kt.kind            AS kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE ci.role_id = 1
      AND ci.nr_order = 1
      AND t.production_year IS NOT NULL
),
keyword_agg AS (
    -- Count distinct movies for each (kind, production_year, keyword)
    SELECT
        mc.kind,
        mc.production_year,
        k.keyword,
        COUNT(DISTINCT mc.movie_id) AS movie_cnt
    FROM movie_cast mc
    JOIN movie_keyword mk ON mk.movie_id = mc.movie_id
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY mc.kind, mc.production_year, k.keyword
),
ranked_keywords AS (
    -- Rank keywords per (kind, production_year) by number of movies
    SELECT
        kind,
        production_year,
        keyword,
        movie_cnt,
        ROW_NUMBER() OVER (PARTITION BY kind, production_year ORDER BY movie_cnt DESC) AS rn
    FROM keyword_agg
)
SELECT
    kind,
    production_year,
    keyword,
    movie_cnt
FROM ranked_keywords
WHERE rn <= 5
ORDER BY kind, production_year, rn
