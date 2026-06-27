/* Top 10 movies (kind_id = 1) released from the year 2000 onward, ranked by total number of cast entries */
WITH movie_cast_stats AS (
    SELECT
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        COUNT(c.id) AS total_cast,
        COUNT(DISTINCT c.person_id) AS distinct_persons,
        AVG(c.nr_order) AS avg_nr_order,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count,
        COUNT(DISTINCT c.role_id) AS distinct_roles,
        AVG(c.person_role_id) AS avg_person_role_id
    FROM cast_info c
    JOIN title t
        ON c.movie_id = t.id
    WHERE t.production_year >= 2000
      AND t.kind_id = 1
    GROUP BY t.id, t.title, t.production_year, t.kind_id
)
SELECT
    title_id,
    movie_title,
    production_year,
    total_cast,
    distinct_persons,
    avg_nr_order,
    notes_count,
    distinct_roles,
    avg_person_role_id
FROM movie_cast_stats
ORDER BY total_cast DESC
LIMIT 10
