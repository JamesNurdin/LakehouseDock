/*
  Query: Top 10 persons with the most alternate names (aka_name)
  - Joins the `name` table to `aka_name` on the allowed key (aka_name.person_id = name.id).
  - Counts how many alternate names each person has.
  - Ranks persons by that count and returns the highest‑ranked 10.
  - Demonstrates grouping, aggregation, a window function and ordering.
*/
WITH per_person_counts AS (
    SELECT
        n.id      AS person_id,
        n.name    AS person_name,
        n.gender  AS gender,
        COUNT(a.id) AS aka_name_count
    FROM name n
    LEFT JOIN aka_name a
        ON a.person_id = n.id
    GROUP BY n.id, n.name, n.gender
)
SELECT
    person_id,
    person_name,
    gender,
    aka_name_count,
    RANK() OVER (ORDER BY aka_name_count DESC) AS rank_by_aka_names
FROM per_person_counts
WHERE aka_name_count > 0
ORDER BY aka_name_count DESC
LIMIT 10
