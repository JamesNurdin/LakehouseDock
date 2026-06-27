WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.answercount) AS total_answer_count,
        SUM(p.commentcount) AS total_comment_count,
        SUM(p.favoritecount) AS total_favorite_count
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS votes_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
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
user_posthistory_on_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS posthistory_on_user_posts
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
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
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(uphp.posthistory_on_user_posts, 0) AS posthistory_on_user_posts,
    COALESCE(ul.postlink_count, 0) AS postlink_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    -- total engagement metric across all activity types
    COALESCE(up.post_count, 0) +
    COALESCE(uc.comment_count, 0) +
    COALESCE(uvc.votes_cast, 0) +
    COALESCE(uvr.votes_received, 0) +
    COALESCE(ub.badge_count, 0) +
    COALESCE(uph.posthistory_count, 0) +
    COALESCE(uphp.posthistory_on_user_posts, 0) +
    COALESCE(ul.postlink_count, 0) +
    COALESCE(ut.tag_count, 0) AS total_engagements
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast uvc ON u.id = uvc.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.userid
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_posthistory uph ON u.id = uph.userid
LEFT JOIN user_posthistory_on_posts uphp ON u.id = uphp.userid
LEFT JOIN user_postlinks ul ON u.id = ul.userid
LEFT JOIN user_tags ut ON u.id = ut.userid
ORDER BY total_engagements DESC
LIMIT 10
