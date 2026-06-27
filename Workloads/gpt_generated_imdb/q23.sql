/*
   Top‑10 movies released from the year 2000 onward, ordered by their rating (if available).
   For each movie the query shows:
     • Title and kind (e.g., movie, TV series)
     • Production year
     • Rating (from movie_info where info_type.info = 'rating')
     • Number of distinct keywords attached to the title
     • Number of distinct cast members
     • Number of distinct companies involved
   All joins follow the allowed join rules for the IMDb Iceberg tables.
*/
WITH movie_ratings AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    t.title,
    kt.kind,
    t.production_year,
    mr.rating,
    mk.keyword_count,
    mcc.cast_count,
    mco.company_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_ratings mr ON mr.movie_id = t.id
LEFT JOIN movie_keywords mk ON mk.movie_id = t.id
LEFT JOIN movie_cast_counts mcc ON mcc.movie_id = t.id
LEFT JOIN movie_company_counts mco ON mco.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY mr.rating DESC NULLS LAST
LIMIT 10
