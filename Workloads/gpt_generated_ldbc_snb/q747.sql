WITH friend_counts AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT CASE WHEN kp.person1_id = p.id THEN kp.person2_id END) +
           COUNT(DISTINCT CASE WHEN kp.person2_id = p.id THEN kp.person1_id END) AS friend_count
    FROM person p
    LEFT JOIN person_knows_person kp
      ON kp.person1_id = p.id OR kp.person2_id = p.id
    GROUP BY p.id
),
interest_counts AS (
    SELECT person_id,
           COUNT(DISTINCT tag_id) AS interest_count
    FROM person_has_interest_tag
    GROUP BY person_id
),
likes_counts AS (
    SELECT person_id,
           COUNT(DISTINCT post_id) AS likes_count
    FROM person_likes_post
    GROUP BY person_id
),
comment_stats AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS comment_count,
           AVG(length) AS avg_comment_length,
           SUM(length) AS total_comment_length,
           COUNT(CASE WHEN parent_comment_id IS NOT NULL THEN 1 END) AS reply_comment_count
    FROM comment
    GROUP BY creator_person_id
),
study_counts AS (
    SELECT person_id,
           COUNT(DISTINCT university_id) AS university_count,
           MIN(class_year) AS earliest_class_year,
           MAX(class_year) AS latest_class_year
    FROM person_study_at_university
    GROUP BY person_id
)
SELECT p.id,
       p.first_name,
       p.last_name,
       p.gender,
       COALESCE(fc.friend_count, 0)               AS friend_count,
       COALESCE(ic.interest_count, 0)             AS interest_count,
       COALESCE(lc.likes_count, 0)                AS likes_count,
       COALESCE(cs.comment_count, 0)              AS comment_count,
       COALESCE(cs.avg_comment_length, 0)         AS avg_comment_length,
       COALESCE(cs.total_comment_length, 0)       AS total_comment_length,
       COALESCE(cs.reply_comment_count, 0)        AS reply_comment_count,
       COALESCE(sc.university_count, 0)           AS university_count,
       sc.earliest_class_year,
       sc.latest_class_year
FROM person p
LEFT JOIN friend_counts fc ON fc.person_id = p.id
LEFT JOIN interest_counts ic ON ic.person_id = p.id
LEFT JOIN likes_counts lc ON lc.person_id = p.id
LEFT JOIN comment_stats cs ON cs.person_id = p.id
LEFT JOIN study_counts sc ON sc.person_id = p.id
WHERE p.gender = 'female'
ORDER BY friend_count DESC, comment_count DESC
LIMIT 100
