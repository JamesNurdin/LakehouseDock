WITH person_age AS (
    SELECT
        id,
        gender,
        birthday,
        date_diff('year', CAST(birthday AS date), current_date) AS age
    FROM person
    WHERE birthday IS NOT NULL
),
person_tag AS (
    SELECT
        p.id AS person_id,
        p.gender,
        p.age,
        t.id AS tag_id,
        t.name AS tag_name
    FROM person_has_interest_tag pht
    JOIN person_age p ON pht.person_id = p.id
    JOIN tag t ON pht.tag_id = t.id
)
SELECT
    tag_id,
    tag_name,
    COUNT(DISTINCT person_id) AS total_persons,
    SUM(CASE WHEN gender = 'male' THEN 1 ELSE 0 END) AS male_persons,
    SUM(CASE WHEN gender = 'female' THEN 1 ELSE 0 END) AS female_persons,
    AVG(age) AS avg_age
FROM person_tag
GROUP BY tag_id, tag_name
ORDER BY total_persons DESC
LIMIT 10
