WITH user_posts AS (
    SELECT 
        p.owneruserid AS id,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_view_count,
        AVG(p.viewcount) AS avg_view_count,
        SUM(p.answercount) AS total_answer_count,
        SUM(p.commentcount) AS total_comment_count,
        SUM(p.favoritecount) AS total_favorite_count
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT 
        c.userid AS id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT 
        v.userid AS id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(v.bountyamount) AS total_bounty_given
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT 
        b.userid AS id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT 
        ph.userid AS id,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_tags AS (
    SELECT 
        p.owneruserid AS id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT 
        p.owneruserid AS id,
        COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT 
    u.id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(up.avg_view_count, 0) AS avg_view_count,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.upvote_count, 0) AS upvote_count,
    COALESCE(uv.downvote_count, 0) AS downvote_count,
    COALESCE(uv.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(upl.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.id = u.id
LEFT JOIN user_comments uc ON uc.id = u.id
LEFT JOIN user_votes uv ON uv.id = u.id
LEFT JOIN user_badges ub ON ub.id = u.id
LEFT JOIN user_posthistory uph ON uph.id = u.id
LEFT JOIN user_tags ut ON ut.id = u.id
LEFT JOIN user_postlinks upl ON upl.id = u.id
ORDER BY u.reputation DESC
LIMIT 10
