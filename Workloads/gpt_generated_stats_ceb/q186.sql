WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            AVG(p.score) AS avg_post_score,
            SUM(p.favoritecount) AS total_favorites,
            SUM(p.viewcount) AS total_views,
            SUM(p.answercount) AS total_answers,
            SUM(p.commentcount) AS total_comments_on_posts
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(c.score) AS total_comment_score,
            AVG(c.score) AS avg_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS vote_cast_count,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_amount,
            COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_cast_count,
            COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_cast_count
        FROM votes v
        GROUP BY v.userid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(uv.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(uv.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(uv.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    CASE WHEN u.downvotes = 0 THEN NULL ELSE CAST(u.upvotes AS double) / u.downvotes END AS upvote_downvote_ratio
FROM users u
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN user_votes uv ON u.id = uv.user_id
LEFT JOIN user_badges ub ON u.id = ub.user_id
LEFT JOIN user_posthistory uph ON u.id = uph.user_id
ORDER BY total_post_score DESC
LIMIT 20
