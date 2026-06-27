WITH
    base_users AS (
        SELECT
            id AS user_id,
            reputation
        FROM users
    ),
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS total_post_score,
            COALESCE(SUM(viewcount), 0) AS total_post_views,
            COALESCE(SUM(answercount), 0) AS total_answer_count,
            COALESCE(SUM(commentcount), 0) AS total_comment_count,
            COALESCE(SUM(favoritecount), 0) AS total_favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast_count,
            COALESCE(SUM(bountyamount), 0) AS bounty_given
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS votes_received_count,
            COALESCE(SUM(v.bountyamount), 0) AS bounty_received
        FROM votes v
        JOIN posts p
            ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory_by_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_by_user_count
        FROM posthistory
        GROUP BY userid
    ),
    user_posthistory_on_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(ph.id) AS posthistory_on_user_posts_count
        FROM posthistory ph
        JOIN posts p
            ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_posts_edited AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS posts_edited_count
        FROM posts
        GROUP BY lasteditoruserid
    )
SELECT
    u.user_id,
    u.reputation,
    COALESCE(pu.post_count, 0) AS post_count,
    COALESCE(pu.total_post_score, 0) AS total_post_score,
    COALESCE(pu.total_post_views, 0) AS total_post_views,
    COALESCE(pu.total_answer_count, 0) AS total_answer_count,
    COALESCE(pu.total_comment_count, 0) AS total_comment_count,
    COALESCE(pu.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(bu.badge_count, 0) AS badge_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.bounty_given, 0) AS bounty_given,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.bounty_received, 0) AS bounty_received,
    COALESCE(phu.posthistory_by_user_count, 0) AS posthistory_by_user_count,
    COALESCE(php.posthistory_on_user_posts_count, 0) AS posthistory_on_user_posts_count,
    COALESCE(pe.posts_edited_count, 0) AS posts_edited_count,
    (
        COALESCE(pu.post_count, 0) * 10
        + COALESCE(pu.total_post_score, 0) * 2
        + COALESCE(bu.badge_count, 0) * 5
        + COALESCE(vc.votes_cast_count, 0) * 1
        + COALESCE(vr.votes_received_count, 0) * 2
        + COALESCE(phu.posthistory_by_user_count, 0) * 1
        + COALESCE(php.posthistory_on_user_posts_count, 0) * 1
        + COALESCE(pe.posts_edited_count, 0) * 3
    ) AS activity_score
FROM base_users u
LEFT JOIN user_posts pu
    ON pu.user_id = u.user_id
LEFT JOIN user_badges bu
    ON bu.user_id = u.user_id
LEFT JOIN user_votes_cast vc
    ON vc.user_id = u.user_id
LEFT JOIN user_votes_received vr
    ON vr.user_id = u.user_id
LEFT JOIN user_posthistory_by_user phu
    ON phu.user_id = u.user_id
LEFT JOIN user_posthistory_on_posts php
    ON php.user_id = u.user_id
LEFT JOIN user_posts_edited pe
    ON pe.user_id = u.user_id
WHERE COALESCE(pu.post_count, 0) > 0
ORDER BY activity_score DESC
LIMIT 100
