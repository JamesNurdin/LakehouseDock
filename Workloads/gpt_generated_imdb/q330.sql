/*
  Top keywords for movies (kind_id = 1) released after 2000.
  For each keyword we show:
    • Number of distinct movies that use the keyword
    • Earliest and latest production year among those movies
    • Average number of rows in movie_info per movie (as a proxy for available metadata)
  The result is limited to keywords that appear on at least 10 movies and the
  top 20 keywords are returned ordered by movie count and then by average info.
*/
WITH filtered_movies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id
    FROM title t
    WHERE t.production_year > 2000
      AND t.kind_id = 1
),
movie_info_counts AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_count
    FROM movie_info mi
    GROUP BY mi.movie_id
),
keyword_stats AS (
    SELECT
        k.keyword,
        COUNT(DISTINCT fm.title_id) AS movie_count,
        MIN(fm.production_year) AS earliest_year,
        MAX(fm.production_year) AS latest_year,
        AVG(COALESCE(mic.info_count, 0)) AS avg_info_per_movie
    FROM filtered_movies fm
    JOIN movie_keyword mk
        ON mk.movie_id = fm.title_id
    JOIN keyword k
        ON k.id = mk.keyword_id
    LEFT JOIN movie_info_counts mic
        ON mic.movie_id = fm.title_id
    GROUP BY k.keyword
)
SELECT
    keyword,
    movie_count,
    earliest_year,
    latest_year,
    avg_info_per_movie
FROM keyword_stats
WHERE movie_count >= 10
ORDER BY movie_count DESC, avg_info_per_movie DESC
LIMIT 20
