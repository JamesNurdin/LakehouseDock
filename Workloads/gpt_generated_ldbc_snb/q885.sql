WITH person_age AS (
    SELECT
        p.id,
        p.gender,
        date_diff('year', CAST(p.birthday AS date), current_date) AS age
    FROM person p
    WHERE p.birthday IS NOT NULL
),
person_tag AS (
    SELECT
        pit.person_id,
        pit.tag_id
    FROM person_has_interest_tag pit
)
SELECT
    t.name AS tag_name,
    COUNT(DISTINCT pa.id) AS person_count,
    COUNT(DISTINCT CASE WHEN pa.gender = 'male' THEN pa.id END) AS male_count,
    COUNT(DISTINCT CASE WHEN pa.gender = 'female' THEN pa.id END) AS female_count,
    AVG(pa.age) AS avg_age
FROM person_tag pt
JOIN person_age pa ON pt.person_id = pa.id
JOIN tag t ON pt.tag_id = t.id
GROUP BY t.name
ORDER BY person_count DESC
LIMIT 20
