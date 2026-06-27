WITH comment_metrics AS (
    SELECT p.id AS person_id,
           COUNT(c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM person p
    LEFT JOIN comment c ON c.creator_person_id = p.id
    GROUP BY p.id
),
post_metrics AS (
    SELECT p.id AS person_id,
           COUNT(po.id) AS post_count,
           AVG(po.length) AS avg_post_length
    FROM person p
    LEFT JOIN post po ON po.creator_person_id = p.id
    GROUP BY p.id
),
likes_given_comments AS (
    SELECT p.id AS person_id,
           COUNT(plc.person_id) AS likes_given_on_comments
    FROM person p
    LEFT JOIN person_likes_comment plc ON plc.person_id = p.id
    GROUP BY p.id
),
likes_given_posts AS (
    SELECT p.id AS person_id,
           COUNT(plp.person_id) AS likes_given_on_posts
    FROM person p
    LEFT JOIN person_likes_post plp ON plp.person_id = p.id
    GROUP BY p.id
),
likes_received_comments AS (
    SELECT p.id AS person_id,
           COUNT(plc.person_id) AS likes_received_on_comments
    FROM person p
    LEFT JOIN comment c ON c.creator_person_id = p.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY p.id
),
likes_received_posts AS (
    SELECT p.id AS person_id,
           COUNT(plp.person_id) AS likes_received_on_posts
    FROM person p
    LEFT JOIN post po ON po.creator_person_id = p.id
    LEFT JOIN person_likes_post plp ON plp.post_id = po.id
    GROUP BY p.id
)
SELECT p.id AS person_id,
       p.first_name,
       p.last_name,
       COALESCE(cm.comment_count, 0) AS comment_count,
       COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(pm.post_count, 0) AS post_count,
       COALESCE(pm.avg_post_length, 0) AS avg_post_length,
       COALESCE(lgc.likes_given_on_comments, 0) AS likes_given_on_comments,
       COALESCE(lgp.likes_given_on_posts, 0) AS likes_given_on_posts,
       COALESCE(lrc.likes_received_on_comments, 0) AS likes_received_on_comments,
       COALESCE(lrp.likes_received_on_posts, 0) AS likes_received_on_posts,
       COALESCE(lrc.likes_received_on_comments, 0) + COALESCE(lrp.likes_received_on_posts, 0) AS total_likes_received
FROM person p
LEFT JOIN comment_metrics cm ON cm.person_id = p.id
LEFT JOIN post_metrics pm ON pm.person_id = p.id
LEFT JOIN likes_given_comments lgc ON lgc.person_id = p.id
LEFT JOIN likes_given_posts lgp ON lgp.person_id = p.id
LEFT JOIN likes_received_comments lrc ON lrc.person_id = p.id
LEFT JOIN likes_received_posts lrp ON lrp.person_id = p.id
ORDER BY total_likes_received DESC, comment_count DESC
LIMIT 10
