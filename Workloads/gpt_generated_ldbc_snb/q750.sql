WITH friends_raw AS (
        SELECT person1_id AS person_id,
               person2_id AS friend_id
        FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id,
               person1_id AS friend_id
        FROM person_knows_person
    ),
    friends_counts AS (
        SELECT fr.person_id,
               COUNT(DISTINCT fr.friend_id) AS num_friends
        FROM friends_raw fr
        GROUP BY fr.person_id
    ),
    likes_counts AS (
        SELECT plp.person_id,
               COUNT(DISTINCT plp.post_id) AS num_liked_posts
        FROM person_likes_post plp
        GROUP BY plp.person_id
    ),
    moderated_counts AS (
        SELECT f.moderator_person_id AS person_id,
               COUNT(DISTINCT f.id) AS num_moderated_forums
        FROM forum f
        GROUP BY f.moderator_person_id
    ),
    education AS (
        SELECT psu.person_id,
               MAX(psu.university_id) AS university_id,
               MAX(psu.class_year) AS class_year
        FROM person_study_at_university psu
        GROUP BY psu.person_id
    )
SELECT p.id,
       p.first_name,
       p.last_name,
       p.gender,
       e.university_id,
       e.class_year,
       COALESCE(fc.num_friends, 0)      AS num_friends,
       COALESCE(lc.num_liked_posts, 0) AS num_liked_posts,
       COALESCE(mc.num_moderated_forums, 0) AS num_moderated_forums
FROM person p
LEFT JOIN friends_counts fc ON fc.person_id = p.id
LEFT JOIN likes_counts lc ON lc.person_id = p.id
LEFT JOIN moderated_counts mc ON mc.person_id = p.id
LEFT JOIN education e ON e.person_id = p.id
ORDER BY num_friends DESC, p.id
LIMIT 100
