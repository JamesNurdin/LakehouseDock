WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.answercount) AS total_answercount,
        SUM(p.commentcount) AS total_commentcount,
        SUM(p.favoritecount) AS total_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count,
        SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS vote_cast_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS userid,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_linked_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT pl.id) AS linked_post_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_post_comment_count,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(uv.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(uv.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ulp.linked_post_count, 0) AS linked_post_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_linked_posts ulp ON ulp.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
