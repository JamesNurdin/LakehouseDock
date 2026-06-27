/*
  Top 10 production companies by number of movies produced, with the average rating of their movies
  and the total distinct keywords associated with those movies.
  The query uses only the allowed tables and join relationships.
*/
WITH company_movies AS (
    SELECT
        mc.company_id,
        t.id AS movie_id,
        t.title,
        t.production_year,
        mi.info AS rating_str
    FROM movie_companies mc
    JOIN title t               ON mc.movie_id = t.id
    JOIN company_type ct       ON mc.company_type_id = ct.id
    JOIN movie_info mi         ON mi.movie_id = t.id
    JOIN info_type it          ON mi.info_type_id = it.id
    WHERE ct.kind = 'production'
      AND it.info = 'rating'
),
company_ratings AS (
    SELECT
        company_id,
        COUNT(DISTINCT movie_id) AS total_movies,
        AVG(TRY_CAST(rating_str AS DOUBLE)) AS avg_rating
    FROM company_movies
    GROUP BY company_id
),
company_keywords AS (
    SELECT
        mc.company_id,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM movie_companies mc
    JOIN title t               ON mc.movie_id = t.id
    JOIN company_type ct       ON mc.company_type_id = ct.id
    JOIN movie_keyword mk      ON mk.movie_id = t.id
    JOIN keyword k             ON mk.keyword_id = k.id
    WHERE ct.kind = 'production'
    GROUP BY mc.company_id
)
SELECT
    cr.company_id,
    cr.total_movies,
    cr.avg_rating,
    ck.total_keywords
FROM company_ratings cr
LEFT JOIN company_keywords ck
    ON cr.company_id = ck.company_id
ORDER BY cr.total_movies DESC
LIMIT 10
