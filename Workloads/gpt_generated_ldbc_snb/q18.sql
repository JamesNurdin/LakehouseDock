WITH person_friends AS (
    SELECT p.id AS person_id,
           p.gender,
           COUNT(DISTINCT pkp.person2_id) AS friends_count
    FROM person p
    LEFT JOIN person_knows_person pkp
        ON pkp.person1_id = p.id
    GROUP BY p.id, p.gender
),
person_tags AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT pit.tag_id) AS tags_count
    FROM person p
    LEFT JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    GROUP BY p.id
)
SELECT pf.gender,
       AVG(pf.friends_count) AS avg_friends_per_person,
       AVG(pt.tags_count) AS avg_tags_per_person
FROM person_friends pf
JOIN person_tags pt
    ON pt.person_id = pf.person_id
GROUP BY pf.gender
ORDER BY avg_friends_per_person DESC
