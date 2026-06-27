WITH
    posts_owned AS (
        SELECT owneruserid,
               COUNT(*) AS posts_owned,
               SUM(score) AS total_post_score,
               SUM(viewcount) AS total_viewcount
        FROM posts
        GROUP BY owneruserid
    ),
    posts_edited AS (
        SELECT lasteditoruserid,
               COUNT(*) AS posts_edited
        FROM posts
        GROUP BY lasteditoruserid
    ),
    comments_made AS (
        SELECT userid,
               COUNT(*) AS comments_made
        FROM comments
        GROUP BY userid
    ),
    votes_cast AS (
        SELECT userid,
               COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    badges_earned AS (
        SELECT userid,
               COUNT(*) AS badges_earned
        FROM badges
        GROUP BY userid
    ),
    posthistory_authored AS (
        SELECT userid,
               COUNT(*) AS posthistory_authored
        FROM posthistory
        GROUP BY userid
    ),
    votes_received AS (
        SELECT p.owneruserid AS user_id,
               COUNT(v.id) AS votes_received
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    comments_received AS (
        SELECT p.owneruserid AS user_id,
               COUNT(c.id) AS comments_received
        FROM posts p
        LEFT JOIN comments c ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_as_source AS (
        SELECT p.owneruserid AS user_id,
               COUNT(pl.id) AS postlinks_as_source
        FROM posts p
        LEFT JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_as_target AS (
        SELECT p.owneruserid AS user_id,
               COUNT(pl.id) AS postlinks_as_target
        FROM posts p
        LEFT JOIN postlinks pl ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    tags_associated AS (
        SELECT p.owneruserid AS user_id,
               COUNT(t.id) AS tags_associated
        FROM posts p
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(p_owned.posts_owned, 0) AS posts_owned,
    COALESCE(p_owned.total_post_score, 0) AS total_post_score,
    COALESCE(p_owned.total_viewcount, 0) AS total_viewcount,
    COALESCE(p_edited.posts_edited, 0) AS posts_edited,
    COALESCE(c_made.comments_made, 0) AS comments_made,
    COALESCE(v_cast.votes_cast, 0) AS votes_cast,
    COALESCE(b_earned.badges_earned, 0) AS badges_earned,
    COALESCE(ph_auth.posthistory_authored, 0) AS posthistory_authored,
    COALESCE(v_recv.votes_received, 0) AS votes_received,
    COALESCE(c_recv.comments_received, 0) AS comments_received,
    COALESCE(pl_src.postlinks_as_source, 0) AS postlinks_as_source,
    COALESCE(pl_tgt.postlinks_as_target, 0) AS postlinks_as_target,
    COALESCE(t_assoc.tags_associated, 0) AS tags_associated
FROM users u
LEFT JOIN posts_owned p_owned ON p_owned.owneruserid = u.id
LEFT JOIN posts_edited p_edited ON p_edited.lasteditoruserid = u.id
LEFT JOIN comments_made c_made ON c_made.userid = u.id
LEFT JOIN votes_cast v_cast ON v_cast.userid = u.id
LEFT JOIN badges_earned b_earned ON b_earned.userid = u.id
LEFT JOIN posthistory_authored ph_auth ON ph_auth.userid = u.id
LEFT JOIN votes_received v_recv ON v_recv.user_id = u.id
LEFT JOIN comments_received c_recv ON c_recv.user_id = u.id
LEFT JOIN postlinks_as_source pl_src ON pl_src.user_id = u.id
LEFT JOIN postlinks_as_target pl_tgt ON pl_tgt.user_id = u.id
LEFT JOIN tags_associated t_assoc ON t_assoc.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
