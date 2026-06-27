WITH
    user_base AS (
        SELECT
            id,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    ),
    posts_owned AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS posts_owned,
            COALESCE(SUM(score), 0) AS total_score,
            COALESCE(SUM(viewcount), 0) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    posts_edited AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS posts_edited
        FROM posts
        GROUP BY lasteditoruserid
    ),
    votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    posthistory_actions AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_actions
        FROM posthistory
        GROUP BY userid
    ),
    postlinks_owned AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlinks_owned
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.id AS user_id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(po.posts_owned, 0) AS posts_owned,
    COALESCE(po.total_score, 0) AS total_post_score,
    COALESCE(po.total_views, 0) AS total_post_views,
    COALESCE(pe.posts_edited, 0) AS posts_edited,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(ph.posthistory_actions, 0) AS posthistory_actions,
    COALESCE(pl.postlinks_owned, 0) AS postlinks_owned,
    CASE WHEN COALESCE(po.posts_owned, 0) > 0 THEN CAST(COALESCE(po.total_score, 0) AS double) / po.posts_owned ELSE 0 END AS avg_score_per_post,
    CASE WHEN COALESCE(po.posts_owned, 0) > 0 THEN CAST(COALESCE(po.total_views, 0) AS double) / po.posts_owned ELSE 0 END AS avg_views_per_post,
    CASE WHEN COALESCE(po.posts_owned, 0) > 0 THEN CAST(COALESCE(vr.votes_received, 0) AS double) / po.posts_owned ELSE 0 END AS avg_votes_received_per_post
FROM user_base ub
LEFT JOIN posts_owned po ON ub.id = po.user_id
LEFT JOIN posts_edited pe ON ub.id = pe.user_id
LEFT JOIN votes_received vr ON ub.id = vr.user_id
LEFT JOIN votes_cast vc ON ub.id = vc.user_id
LEFT JOIN posthistory_actions ph ON ub.id = ph.user_id
LEFT JOIN postlinks_owned pl ON ub.id = pl.user_id
ORDER BY ub.reputation DESC
LIMIT 100
