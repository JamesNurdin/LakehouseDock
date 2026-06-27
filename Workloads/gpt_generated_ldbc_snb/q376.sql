WITH members AS (
    SELECT fm.forum_id,
           fm.person_id AS member_id
    FROM forum_has_member_person fm
),
posts AS (
    SELECT p.container_forum_id AS forum_id,
           p.id AS post_id,
           p.length
    FROM post p
),
likes AS (
    SELECT m.forum_id,
           plc.person_id AS liker_id
    FROM members m
    JOIN person_likes_comment plc ON plc.person_id = m.member_id
),
friendships AS (
    SELECT m1.forum_id,
           pkp.person1_id,
           pkp.person2_id
    FROM members m1
    JOIN person_knows_person pkp ON pkp.person1_id = m1.member_id
    JOIN members m2 ON m2.forum_id = m1.forum_id
                     AND m2.member_id = pkp.person2_id
),
studies AS (
    SELECT m.forum_id,
           psu.person_id AS student_id,
           psu.university_id
    FROM members m
    JOIN person_study_at_university psu ON psu.person_id = m.member_id
)
SELECT f.id AS forum_id,
       f.title,
       f.creation_date AS forum_creation_date,
       mod.first_name AS moderator_first_name,
       mod.last_name  AS moderator_last_name,
       COUNT(DISTINCT members.member_id)                     AS member_count,
       COUNT(DISTINCT posts.post_id)                        AS post_count,
       AVG(posts.length)                                    AS avg_post_length,
       COUNT(DISTINCT likes.liker_id)                       AS members_who_liked_comment,
       COUNT(DISTINCT friendships.person1_id)               AS friendship_pairs_within_forum,
       COUNT(DISTINCT studies.student_id)                   AS members_who_studied,
       COUNT(DISTINCT studies.university_id)                AS distinct_universities_represented
FROM forum f
LEFT JOIN person mod ON f.moderator_person_id = mod.id
LEFT JOIN members      ON members.forum_id = f.id
LEFT JOIN posts        ON posts.forum_id = f.id
LEFT JOIN likes        ON likes.forum_id = f.id
LEFT JOIN friendships  ON friendships.forum_id = f.id
LEFT JOIN studies      ON studies.forum_id = f.id
GROUP BY f.id, f.title, f.creation_date, mod.first_name, mod.last_name
ORDER BY member_count DESC
LIMIT 10
