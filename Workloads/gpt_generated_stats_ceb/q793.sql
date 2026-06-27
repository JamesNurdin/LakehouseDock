WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(p.id) AS post_count,
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
        c.userid AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(v.id) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(ph.id) AS posthistory_by_user
    FROM posthistory ph
    GROUP BY ph.userid
),
user_posthistory_on_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(ph.id) AS posthistory_on_user_posts
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_source AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS postlinks_as_source
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_target AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS postlinks_as_target
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(t.id) AS tag_count,
        SUM(t.count) AS total_tag_usage
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0.0) AS avg_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0.0) AS avg_comment_score,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_by_user, 0) AS posthistory_by_user,
    COALESCE(uphp.posthistory_on_user_posts, 0) AS posthistory_on_user_posts,
    COALESCE(uls.postlinks_as_source, 0) AS postlinks_as_source,
    COALESCE(ult.postlinks_as_target, 0) AS postlinks_as_target,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(ut.total_tag_usage, 0) AS total_tag_usage
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_posthistory_on_posts uphp ON uphp.user_id = u.id
LEFT JOIN user_postlinks_source uls ON uls.user_id = u.id
LEFT JOIN user_postlinks_target ult ON ult.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
