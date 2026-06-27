WITH movie_ratings AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_production_companies AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS prod_company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
movie_keywords AS (
    SELECT mk.movie_id,
           array_agg(DISTINCT k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_stats AS (
    SELECT t.id,
           t.title,
           t.production_year,
           kt.kind AS genre,
           COALESCE(mr.rating, 0) AS rating,
           COALESCE(mcc.cast_count, 0) AS cast_count,
           COALESCE(mpc.prod_company_count, 0) AS prod_company_count,
           mk.keywords
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_ratings mr ON t.id = mr.movie_id
    LEFT JOIN movie_cast_counts mcc ON t.id = mcc.movie_id
    LEFT JOIN movie_production_companies mpc ON t.id = mpc.movie_id
    LEFT JOIN movie_keywords mk ON t.id = mk.movie_id
    WHERE t.production_year >= 2000
)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY genre ORDER BY rating DESC, cast_count DESC) AS rank_in_genre
    FROM movie_stats
) ranked
WHERE rank_in_genre <= 5
ORDER BY genre, rank_in_genre
