WITH person_aka_counts AS (
    SELECT an.person_id AS person_id,
           COUNT(an.id) AS aka_name_count
    FROM aka_name an
    GROUP BY an.person_id
)
SELECT n.id,
       n.name,
       n.gender,
       pac.aka_name_count,
       ROW_NUMBER() OVER (PARTITION BY n.gender ORDER BY pac.aka_name_count DESC) AS gender_rank
FROM name n
JOIN person_aka_counts pac
  ON pac.person_id = n.id
ORDER BY n.gender, gender_rank
LIMIT 20
