WITH comment_like_stats AS (
    SELECT
        c.id AS comment_id,
        c.creator_person_id,
        c.parent_post_id,
        c.length,
        COUNT(plc.person_id) AS like_cnt,
        COUNT(DISTINCT plc.person_id) AS distinct_liker_cnt
    FROM comment c
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY c.id, c.creator_person_id, c.parent_post_id, c.length
),
creator_friend_counts AS (
    SELECT
        pk.person1_id AS creator_id,
        COUNT(DISTINCT pk.person2_id) AS friend_cnt
    FROM person_knows_person pk
    GROUP BY pk.person1_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COUNT(DISTINCT cls.comment_id) AS comment_cnt,
    AVG(cls.length) AS avg_comment_len,
    SUM(cls.like_cnt) AS total_likes,
    COUNT(DISTINCT CASE WHEN cls.like_cnt > 0 THEN cls.comment_id END) AS comments_with_likes,
    AVG(COALESCE(cfc.friend_cnt, 0)) AS avg_creator_friends,
    SUM(cls.like_cnt) * 1.0 / NULLIF(COUNT(DISTINCT cls.comment_id), 0) AS avg_likes_per_comment
FROM comment_like_stats cls
JOIN post p ON cls.parent_post_id = p.id
JOIN forum f ON p.container_forum_id = f.id
LEFT JOIN creator_friend_counts cfc ON cfc.creator_id = cls.creator_person_id
GROUP BY f.id, f.title
ORDER BY comment_cnt DESC
LIMIT 10
