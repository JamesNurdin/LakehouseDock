/* Top 10 movies (produced from year 2000 onward) with the largest distinct cast, showing total cast size and gender breakdown */
WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN n.id END) AS male_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN n.id END) AS female_cast
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN name n ON ci.person_id = n.id
    WHERE t.kind_id = 1
      AND t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
)
SELECT
    title,
    production_year,
    total_cast,
    male_cast,
    female_cast
FROM movie_cast_counts
ORDER BY total_cast DESC
LIMIT 10
