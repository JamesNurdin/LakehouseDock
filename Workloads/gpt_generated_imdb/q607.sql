/*
  Top 10 keywords by the number of distinct movies they appear in, with a ranking column.
  This query joins the `keyword` and `movie_keyword` tables, aggregates the distinct
  movie count per keyword, ranks the keywords by that count, and returns the highest
  ranked rows.
*/
WITH keyword_movie_counts AS (
    SELECT
        k.id AS keyword_id,
        k.keyword,
        k.phonetic_code,
        COUNT(DISTINCT mk.movie_id) AS movie_count
    FROM keyword k
    JOIN movie_keyword mk
        ON mk.keyword_id = k.id
    GROUP BY k.id, k.keyword, k.phonetic_code
),
ranked_keywords AS (
    SELECT
        keyword,
        phonetic_code,
        movie_count,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS rank
    FROM keyword_movie_counts
)
SELECT
    keyword,
    phonetic_code,
    movie_count,
    rank
FROM ranked_keywords
WHERE rank <= 10
ORDER BY rank
