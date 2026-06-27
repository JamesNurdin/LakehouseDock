WITH
    posts AS (
        SELECT p.creator_person_id AS person_id,
               COUNT(*) AS post_count,
               AVG(p.length) AS avg_post_length
        FROM post p
        GROUP BY p.creator_person_id
    ),
    comments AS (
        SELECT c.creator_person_id AS person_id,
               COUNT(*) AS comment_count,
               AVG(c.length) AS avg_comment_length
        FROM comment c
        GROUP BY c.creator_person_id
    ),
    friends AS (
        SELECT pk.person_id,
               COUNT(DISTINCT pk.friend_id) AS friend_count
        FROM (
            SELECT person1_id AS person_id, person2_id AS friend_id
            FROM person_knows_person
            UNION ALL
            SELECT person2_id AS person_id, person1_id AS friend_id
            FROM person_knows_person
        ) pk
        GROUP BY pk.person_id
    ),
    interests AS (
        SELECT i.person_id,
               COUNT(*) AS interest_count
        FROM person_has_interest_tag i
        GROUP BY i.person_id
    ),
    moderators AS (
        SELECT f.moderator_person_id AS person_id,
               COUNT(*) AS moderated_forum_count
        FROM forum f
        GROUP BY f.moderator_person_id
    ),
    university AS (
        SELECT stu.person_id,
               org.name AS university_name
        FROM person_study_at_university stu
        JOIN organisation org
          ON stu.university_id = org.id
        WHERE org.type = 'University'
    )
SELECT per.id AS person_id,
       per.first_name,
       per.last_name,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.avg_post_length, 0) AS avg_post_length,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(f.friend_count, 0) AS friend_count,
       COALESCE(i.interest_count, 0) AS interest_count,
       COALESCE(m.moderated_forum_count, 0) AS moderated_forum_count,
       u.university_name
FROM person per
LEFT JOIN posts p
  ON p.person_id = per.id
LEFT JOIN comments c
  ON c.person_id = per.id
LEFT JOIN friends f
  ON f.person_id = per.id
LEFT JOIN interests i
  ON i.person_id = per.id
LEFT JOIN moderators m
  ON m.person_id = per.id
LEFT JOIN university u
  ON u.person_id = per.id
WHERE COALESCE(m.moderated_forum_count, 0) > 0
ORDER BY (
    COALESCE(p.post_count, 0) +
    COALESCE(c.comment_count, 0) +
    COALESCE(f.friend_count, 0) +
    COALESCE(i.interest_count, 0) +
    COALESCE(m.moderated_forum_count, 0)
) DESC
LIMIT 10
