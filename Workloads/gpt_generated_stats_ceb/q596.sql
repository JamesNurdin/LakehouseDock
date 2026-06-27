WITH
    owned_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posts_owned,
            COALESCE(SUM(p.score), 0) AS total_post_score,
            COALESCE(SUM(p.viewcount), 0) AS total_post_views,
            COALESCE(SUM(p.answercount), 0) AS total_answers,
            COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts,
            COALESCE(SUM(p.favoritecount), 0) AS total_favorites
        FROM posts p
        GROUP BY p.owneruserid
    ),
    edited_posts AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS posts_edited
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badges_earned
        FROM badges b
        GROUP BY b.userid
    ),
    user_comments AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comments_made,
            COALESCE(SUM(c.score), 0) AS total_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    votes_cast AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received,
            COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_by_user AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_entries
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    posthistory_by_type AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posthistory_type_entries
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(op.posts_owned, 0) AS posts_owned,
    COALESCE(op.total_post_score, 0) AS total_post_score,
    COALESCE(op.total_post_views, 0) AS total_post_views,
    COALESCE(op.total_answers, 0) AS total_answers,
    COALESCE(op.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(op.total_favorites, 0) AS total_favorites,
    COALESCE(ep.posts_edited, 0) AS posts_edited,
    COALESCE(ub.badges_earned, 0) AS badges_earned,
    COALESCE(uc.comments_made, 0) AS comments_made,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(phu.posthistory_entries, 0) AS posthistory_entries_by_user,
    COALESCE(pht.posthistory_type_entries, 0) AS posthistory_entries_by_type,
    (
        COALESCE(op.posts_owned, 0) * 1
        + COALESCE(uc.comments_made, 0) * 2
        + COALESCE(vc.votes_cast, 0) * 3
        + COALESCE(vr.votes_received, 0) * 4
        + COALESCE(ub.badges_earned, 0) * 5
        + COALESCE(phu.posthistory_entries, 0) * 6
    ) AS engagement_score
FROM users u
LEFT JOIN owned_posts op ON u.id = op.user_id
LEFT JOIN edited_posts ep ON u.id = ep.user_id
LEFT JOIN user_badges ub ON u.id = ub.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN votes_cast vc ON u.id = vc.user_id
LEFT JOIN votes_received vr ON u.id = vr.user_id
LEFT JOIN posthistory_by_user phu ON u.id = phu.user_id
LEFT JOIN posthistory_by_type pht ON u.id = pht.user_id
ORDER BY engagement_score DESC
LIMIT 100
