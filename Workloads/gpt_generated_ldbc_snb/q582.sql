WITH comment_agg AS (
    SELECT
        creator_person_id AS person_id,
        COUNT(*) AS comment_count,
        SUM(length) AS total_comment_length
    FROM comment
    WHERE creation_date >= '2020-01-01'
    GROUP BY creator_person_id
),
friend_edges AS (
    SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
    UNION ALL
    SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
),
friend_agg AS (
    SELECT
        person_id,
        COUNT(DISTINCT friend_id) AS friend_count
    FROM friend_edges
    GROUP BY person_id
),
study_agg AS (
    SELECT
        person_id,
        COUNT(DISTINCT university_id) AS university_count,
        MAX(class_year) AS latest_class_year
    FROM person_study_at_university
    GROUP BY person_id
),
work_agg AS (
    SELECT
        person_id,
        COUNT(DISTINCT company_id) AS company_count
    FROM person_work_at_company
    GROUP BY person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.total_comment_length, 0) AS total_comment_length,
    COALESCE(fa.friend_count, 0) AS friend_count,
    COALESCE(sa.university_count, 0) AS university_count,
    sa.latest_class_year,
    COALESCE(wa.company_count, 0) AS company_count,
    ROW_NUMBER() OVER (ORDER BY COALESCE(ca.total_comment_length, 0) DESC) AS rank
FROM person p
LEFT JOIN comment_agg ca ON ca.person_id = p.id
LEFT JOIN friend_agg fa ON fa.person_id = p.id
LEFT JOIN study_agg sa ON sa.person_id = p.id
LEFT JOIN work_agg wa ON wa.person_id = p.id
ORDER BY COALESCE(ca.total_comment_length, 0) DESC
LIMIT 10
