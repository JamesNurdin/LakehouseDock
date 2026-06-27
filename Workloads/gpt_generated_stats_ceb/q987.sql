WITH
    user_base AS (
        SELECT
            id AS user_id,
            reputation
        FROM users
    ),
    posts_authored AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS posts_authored,
            COALESCE(SUM(score), 0) AS total_post_score,
            COALESCE(SUM(viewcount), 0) AS total_post_views
        FROM posts
        GROUP BY owneruserid
    ),
    comments_made AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comments_made,
            COALESCE(SUM(score), 0) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast,
            COALESCE(SUM(bountyamount), 0) AS total_bounty_given
        FROM votes
        GROUP BY userid
    ),
    votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badges_earned AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badges_earned
        FROM badges
        GROUP BY userid
    ),
    posthistory_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_events
        FROM posthistory
        GROUP BY userid
    ),
    edits_made AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS edits_made
        FROM posts
        GROUP BY lasteditoruserid
    ),
    posthistory_type_match AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT ph.id) AS posthistory_type_match_cnt
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(pa.posts_authored, 0) AS posts_authored,
    COALESCE(pa.total_post_score, 0) AS total_post_score,
    COALESCE(pa.total_post_views, 0) AS total_post_views,
    COALESCE(cm.comments_made, 0) AS comments_made,
    COALESCE(cm.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(be.badges_earned, 0) AS badges_earned,
    COALESCE(phu.posthistory_events, 0) AS posthistory_events,
    COALESCE(em.edits_made, 0) AS edits_made,
    COALESCE(ptm.posthistory_type_match_cnt, 0) AS posthistory_type_match_cnt
FROM user_base ub
LEFT JOIN posts_authored pa ON ub.user_id = pa.user_id
LEFT JOIN comments_made cm ON ub.user_id = cm.user_id
LEFT JOIN votes_cast vc ON ub.user_id = vc.user_id
LEFT JOIN votes_received vr ON ub.user_id = vr.user_id
LEFT JOIN badges_earned be ON ub.user_id = be.user_id
LEFT JOIN posthistory_user phu ON ub.user_id = phu.user_id
LEFT JOIN edits_made em ON ub.user_id = em.user_id
LEFT JOIN posthistory_type_match ptm ON ub.user_id = ptm.user_id
ORDER BY total_post_score DESC
LIMIT 100
