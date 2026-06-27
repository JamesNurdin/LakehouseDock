WITH movie_base AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        kt.kind AS kind,
        cn.name AS production_company
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN company_type ct
        ON mc.company_type_id = ct.id
    LEFT JOIN company_name cn
        ON mc.company_id = cn.id
    WHERE ct.kind = 'production company'
      AND t.production_year IS NOT NULL
),
movie_actors AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_stats AS (
    SELECT
        mb.movie_id,
        mb.production_year,
        mb.kind,
        mb.production_company,
        COALESCE(ma.actor_cnt, 0) AS actor_cnt,
        COALESCE(mk.keyword_cnt, 0) AS keyword_cnt
    FROM movie_base mb
    LEFT JOIN movie_actors ma
        ON ma.movie_id = mb.movie_id
    LEFT JOIN movie_keywords mk
        ON mk.movie_id = mb.movie_id
),
company_agg AS (
    SELECT
        production_year,
        kind,
        production_company,
        COUNT(DISTINCT movie_id) AS movie_cnt,
        SUM(actor_cnt) AS total_actors,
        SUM(keyword_cnt) AS total_keywords,
        AVG(actor_cnt) AS avg_actors_per_movie,
        AVG(keyword_cnt) AS avg_keywords_per_movie
    FROM movie_stats
    GROUP BY production_year, kind, production_company
),
ranked_companies AS (
    SELECT
        production_year,
        kind,
        production_company,
        movie_cnt,
        total_actors,
        total_keywords,
        avg_actors_per_movie,
        avg_keywords_per_movie,
        ROW_NUMBER() OVER (PARTITION BY production_year, kind ORDER BY movie_cnt DESC) AS rn
    FROM company_agg
)
SELECT
    production_year,
    kind,
    production_company,
    movie_cnt,
    total_actors,
    total_keywords,
    avg_actors_per_movie,
    avg_keywords_per_movie
FROM ranked_companies
WHERE rn = 1
ORDER BY production_year DESC, movie_cnt DESC
LIMIT 100
