WITH friend_counts AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT pkp.person2_id) AS friends_as_person1,
           COUNT(DISTINCT pkp2.person1_id) AS friends_as_person2
    FROM person p
    LEFT JOIN person_knows_person pkp
        ON pkp.person1_id = p.id
    LEFT JOIN person_knows_person pkp2
        ON pkp2.person2_id = p.id
    GROUP BY p.id
),
like_counts AS (
    SELECT p.id AS person_id,
           COUNT(plc.comment_id) AS liked_comments
    FROM person p
    LEFT JOIN person_likes_comment plc
        ON plc.person_id = p.id
    GROUP BY p.id
),
post_counts AS (
    SELECT p.id AS person_id,
           COUNT(post.id) AS posts_created,
           AVG(post.length) AS avg_post_length
    FROM person p
    LEFT JOIN post
        ON post.creator_person_id = p.id
    GROUP BY p.id
)
SELECT p.id,
       p.first_name,
       p.last_name,
       p.gender,
       COALESCE(fc.friends_as_person1, 0) + COALESCE(fc.friends_as_person2, 0) AS total_friends,
       COALESCE(lc.liked_comments, 0) AS total_liked_comments,
       COALESCE(pc.posts_created, 0) AS total_posts,
       COALESCE(pc.avg_post_length, 0) AS avg_post_length,
       (COALESCE(fc.friends_as_person1, 0) + COALESCE(fc.friends_as_person2, 0)) * 2
         + COALESCE(lc.liked_comments, 0) + COALESCE(pc.posts_created, 0) AS activity_score
FROM person p
LEFT JOIN friend_counts fc
    ON fc.person_id = p.id
LEFT JOIN like_counts lc
    ON lc.person_id = p.id
LEFT JOIN post_counts pc
    ON pc.person_id = p.id
ORDER BY activity_score DESC
LIMIT 10
