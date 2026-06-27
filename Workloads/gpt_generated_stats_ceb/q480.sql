WITH user_badges AS (
    SELECT
        b.userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.favoritecount) AS total_favoritecount,
        SUM(p.answercount) AS total_answercount,
        SUM(p.commentcount) AS total_commentcount
    FROM posts p
    GROUP BY p.owneruserid
),
user_votes_given AS (
    SELECT
        v.userid,
        COUNT(*) AS votes_given,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_given,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_given
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid,
        COUNT(*) AS comment_count,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_info AS (
    SELECT
        u.id AS userid,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
)
SELECT
    ui.userid,
    ui.reputation,
    ui.creationdate,
    ui.views,
    ui.upvotes,
    ui.downvotes,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(ug.votes_given, 0) AS votes_given,
    COALESCE(ug.upvotes_given, 0) AS upvotes_given,
    COALESCE(ug.downvotes_given, 0) AS downvotes_given,
    COALESCE(ur.votes_received, 0) AS votes_received,
    COALESCE(ur.upvotes_received, 0) AS upvotes_received,
    COALESCE(ur.downvotes_received, 0) AS downvotes_received,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score
FROM user_info ui
LEFT JOIN user_badges ub ON ub.userid = ui.userid
LEFT JOIN user_posts up ON up.userid = ui.userid
LEFT JOIN user_votes_given ug ON ug.userid = ui.userid
LEFT JOIN user_votes_received ur ON ur.userid = ui.userid
LEFT JOIN user_comments uc ON uc.userid = ui.userid
ORDER BY ui.reputation DESC
LIMIT 100
