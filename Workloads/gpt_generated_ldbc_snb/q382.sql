/*
   Analytical query: Person‑centric activity profile
   - Total number of friends (bidirectional)
   - Number of posts created and their average length
   - Likes received on the person's posts
   - Likes the person has given to others' posts
   - Number of forums the person moderates
   Results are ordered by most connected persons and limited to the top 20.
*/
WITH friends AS (
    SELECT kp.person1_id AS person_id, kp.person2_id AS friend_id
    FROM person_knows_person kp
    UNION ALL
    SELECT kp.person2_id AS person_id, kp.person1_id AS friend_id
    FROM person_knows_person kp
),
friend_counts AS (
    SELECT person_id, COUNT(DISTINCT friend_id) AS total_friends
    FROM friends
    GROUP BY person_id
),
post_counts AS (
    SELECT po.creator_person_id AS person_id,
           COUNT(*) AS post_count,
           AVG(po.length) AS avg_post_length
    FROM post po
    GROUP BY po.creator_person_id
),
likes_received AS (
    SELECT po.creator_person_id AS person_id,
           COUNT(plp.person_id) AS likes_received
    FROM post po
    LEFT JOIN person_likes_post plp
        ON plp.post_id = po.id
    GROUP BY po.creator_person_id
),
likes_given AS (
    SELECT plp.person_id AS person_id,
           COUNT(plp.post_id) AS likes_given
    FROM person_likes_post plp
    GROUP BY plp.person_id
),
moderation AS (
    SELECT f.moderator_person_id AS person_id,
           COUNT(f.id) AS forums_moderated
    FROM forum f
    GROUP BY f.moderator_person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    COALESCE(fc.total_friends, 0) AS total_friends,
    COALESCE(pc.post_count, 0) AS post_count,
    pc.avg_post_length,
    COALESCE(lr.likes_received, 0) AS likes_received,
    COALESCE(lg.likes_given, 0) AS likes_given,
    COALESCE(m.forums_moderated, 0) AS forums_moderated
FROM person p
LEFT JOIN friend_counts fc
    ON fc.person_id = p.id
LEFT JOIN post_counts pc
    ON pc.person_id = p.id
LEFT JOIN likes_received lr
    ON lr.person_id = p.id
LEFT JOIN likes_given lg
    ON lg.person_id = p.id
LEFT JOIN moderation m
    ON m.person_id = p.id
ORDER BY total_friends DESC, post_count DESC
LIMIT 20
