WITH
    posts_owned_agg AS (
        SELECT owneruserid,
               COUNT(*) AS posts_owned,
               SUM(score) AS total_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    posts_edited_agg AS (
        SELECT lasteditoruserid,
               COUNT(*) AS posts_edited
        FROM posts
        GROUP BY lasteditoruserid
    ),
    comments_agg AS (
        SELECT userid,
               COUNT(*) AS comments_made,
               SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    votes_cast_agg AS (
        SELECT userid,
               COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received_agg AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badges_agg AS (
        SELECT userid,
               COUNT(*) AS badges_earned
        FROM badges
        GROUP BY userid
    ),
    posthistory_user_agg AS (
        SELECT userid,
               COUNT(*) AS posthistory_created
        FROM posthistory
        GROUP BY userid
    ),
    posthistory_on_owned_posts_agg AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS posthistory_on_owned_posts
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(po.posts_owned, 0) AS posts_owned,
    COALESCE(po.total_post_score, 0) AS total_post_score,
    COALESCE(pe.posts_edited, 0) AS posts_edited,
    COALESCE(cm.comments_made, 0) AS comments_made,
    COALESCE(cm.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(b.badges_earned, 0) AS badges_earned,
    COALESCE(phu.posthistory_created, 0) AS posthistory_created,
    COALESCE(pho.posthistory_on_owned_posts, 0) AS posthistory_on_owned_posts,
    CASE
        WHEN COALESCE(po.posts_owned, 0) > 0 THEN COALESCE(po.total_post_score, 0) * 1.0 / COALESCE(po.posts_owned, 1)
        ELSE 0
    END AS avg_post_score
FROM users u
LEFT JOIN posts_owned_agg po ON u.id = po.owneruserid
LEFT JOIN posts_edited_agg pe ON u.id = pe.lasteditoruserid
LEFT JOIN comments_agg cm ON u.id = cm.userid
LEFT JOIN votes_cast_agg vc ON u.id = vc.userid
LEFT JOIN votes_received_agg vr ON u.id = vr.userid
LEFT JOIN badges_agg b ON u.id = b.userid
LEFT JOIN posthistory_user_agg phu ON u.id = phu.userid
LEFT JOIN posthistory_on_owned_posts_agg pho ON u.id = pho.userid
ORDER BY u.reputation DESC, avg_post_score DESC
LIMIT 100
