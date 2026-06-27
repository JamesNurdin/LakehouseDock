/* Top 15 persons by a diversity score that combines movie appearances and alternate names */
WITH person_activity AS (
    SELECT
        n.id,
        n.name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(an.id) AS aka_name_count
    FROM name n
    LEFT JOIN cast_info ci
        ON ci.person_id = n.id
    LEFT JOIN aka_name an
        ON an.person_id = n.id
    GROUP BY n.id, n.name, n.gender
)
SELECT
    id,
    name,
    gender,
    movie_count,
    aka_name_count,
    (movie_count * 2) + aka_name_count AS diversity_score
FROM person_activity
WHERE movie_count > 0
ORDER BY diversity_score DESC
LIMIT 15
