WITH
    movie_cast AS (
        SELECT
            t.id AS movie_id,
            t.title,
            t.production_year,
            kt.kind,
            COUNT(DISTINCT ci.person_id) AS cast_size
        FROM title t
        JOIN cast_info ci ON ci.movie_id = t.id
        JOIN name n ON ci.person_id = n.id
        JOIN kind_type kt ON t.kind_id = kt.id
        GROUP BY t.id, t.title, t.production_year, kt.kind
    ),
    movie_keywords AS (
        SELECT
            t.id AS movie_id,
            COUNT(DISTINCT k.id) AS keyword_count
        FROM title t
        JOIN movie_keyword mk ON mk.movie_id = t.id
        JOIN keyword k ON mk.keyword_id = k.id
        GROUP BY t.id
    ),
    movie_metrics AS (
        SELECT
            t.id AS movie_id,
            MAX(CASE WHEN it.info = 'rating' THEN CAST(mi.info AS double) END) AS rating,
            MAX(CASE WHEN it.info = 'runtime' THEN CAST(mi.info AS double) END) AS runtime
        FROM title t
        LEFT JOIN movie_info mi ON mi.movie_id = t.id
        LEFT JOIN info_type it ON mi.info_type_id = it.id
        GROUP BY t.id
    ),
    movie_companies AS (
        SELECT
            t.id AS movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM title t
        JOIN movie_companies mc ON mc.movie_id = t.id
        GROUP BY t.id
    )
SELECT
    mc.title,
    mc.production_year,
    mc.kind,
    mc.cast_size,
    mk.keyword_count,
    mm.rating,
    mm.runtime,
    co.company_count,
    RANK() OVER (PARTITION BY mc.production_year ORDER BY mc.cast_size DESC) AS cast_rank_in_year
FROM movie_cast mc
LEFT JOIN movie_keywords mk ON mk.movie_id = mc.movie_id
LEFT JOIN movie_metrics mm ON mm.movie_id = mc.movie_id
LEFT JOIN movie_companies co ON co.movie_id = mc.movie_id
WHERE mc.production_year >= 2000
ORDER BY mc.production_year DESC, mc.cast_size DESC
LIMIT 100
