WITH friends AS (
    SELECT person1_id AS person_id,
           person2_id AS friend_id
    FROM person_knows_person
    UNION ALL
    SELECT person2_id AS person_id,
           person1_id AS friend_id
    FROM person_knows_person
),
friend_counts AS (
    SELECT f.person_id,
           COUNT(DISTINCT f.friend_id) AS friend_count
    FROM friends f
    GROUP BY f.person_id
),
post_stats AS (
    SELECT p.creator_person_id AS person_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.creator_person_id
),
uni_counts AS (
    SELECT s.person_id,
           COUNT(DISTINCT s.university_id) AS uni_count
    FROM person_study_at_university s
    GROUP BY s.person_id
)
SELECT
    per.id,
    per.first_name,
    per.last_name,
    per.gender,
    COALESCE(fc.friend_count, 0)      AS friend_count,
    COALESCE(ps.post_count, 0)       AS post_count,
    COALESCE(ps.avg_post_length, 0)  AS avg_post_length,
    COALESCE(uc.uni_count, 0)        AS uni_count
FROM person per
LEFT JOIN friend_counts fc ON fc.person_id = per.id
LEFT JOIN post_stats    ps ON ps.person_id = per.id
LEFT JOIN uni_counts    uc ON uc.person_id = per.id
ORDER BY friend_count DESC, per.id
LIMIT 100
