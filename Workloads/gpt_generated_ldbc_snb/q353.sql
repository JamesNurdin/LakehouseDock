WITH friend_edges AS (
    SELECT pk.person1_id AS person_id, pk.person2_id AS friend_id
    FROM person_knows_person pk
    UNION ALL
    SELECT pk.person2_id AS person_id, pk.person1_id AS friend_id
    FROM person_knows_person pk
),
friends AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT fe.friend_id) AS num_friends
    FROM person p
    LEFT JOIN friend_edges fe ON fe.person_id = p.id
    GROUP BY p.id
),
post_likes_agg AS (
    SELECT plp.post_id,
           COUNT(*) AS like_post_cnt
    FROM person_likes_post plp
    GROUP BY plp.post_id
),
comment_likes_agg AS (
    SELECT plc.comment_id,
           COUNT(*) AS like_comment_cnt
    FROM person_likes_comment plc
    GROUP BY plc.comment_id
),
posts AS (
    SELECT p.id AS person_id,
           COUNT(*) AS num_posts,
           AVG(post.length) AS avg_post_length,
           COALESCE(SUM(pl.like_post_cnt), 0) AS likes_received_on_posts
    FROM person p
    LEFT JOIN post post
        ON post.creator_person_id = p.id
    LEFT JOIN post_likes_agg pl
        ON pl.post_id = post.id
    GROUP BY p.id
),
comments AS (
    SELECT p.id AS person_id,
           COUNT(*) AS num_comments,
           AVG(comment.length) AS avg_comment_length,
           COALESCE(SUM(cl.like_comment_cnt), 0) AS likes_received_on_comments
    FROM person p
    LEFT JOIN comment comment
        ON comment.creator_person_id = p.id
    LEFT JOIN comment_likes_agg cl
        ON cl.comment_id = comment.id
    GROUP BY p.id
),
likes_given AS (
    SELECT p.id AS person_id,
           COALESCE(plp_agg.plp_like_cnt, 0) + COALESCE(plc_agg.plc_like_cnt, 0) AS total_likes_given
    FROM person p
    LEFT JOIN (
        SELECT plp.person_id,
               COUNT(*) AS plp_like_cnt
        FROM person_likes_post plp
        GROUP BY plp.person_id
    ) plp_agg
        ON plp_agg.person_id = p.id
    LEFT JOIN (
        SELECT plc.person_id,
               COUNT(*) AS plc_like_cnt
        FROM person_likes_comment plc
        GROUP BY plc.person_id
    ) plc_agg
        ON plc_agg.person_id = p.id
),
interests AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT pht.tag_id) AS num_interests
    FROM person p
    LEFT JOIN person_has_interest_tag pht
        ON pht.person_id = p.id
    GROUP BY p.id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    p.birthday,
    COALESCE(f.num_friends, 0) AS num_friends,
    COALESCE(po.num_posts, 0) AS num_posts,
    COALESCE(co.num_comments, 0) AS num_comments,
    COALESCE(po.avg_post_length, 0) AS avg_post_length,
    COALESCE(co.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(lg.total_likes_given, 0) AS total_likes_given,
    COALESCE(po.likes_received_on_posts, 0) + COALESCE(co.likes_received_on_comments, 0) AS total_likes_received,
    COALESCE(i.num_interests, 0) AS num_interests
FROM person p
LEFT JOIN friends f ON f.person_id = p.id
LEFT JOIN posts po ON po.person_id = p.id
LEFT JOIN comments co ON co.person_id = p.id
LEFT JOIN likes_given lg ON lg.person_id = p.id
LEFT JOIN interests i ON i.person_id = p.id
ORDER BY total_likes_received DESC, num_friends DESC
LIMIT 20
