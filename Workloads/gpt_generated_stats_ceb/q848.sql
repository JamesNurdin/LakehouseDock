WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.answercount) AS total_answercount,
        SUM(p.commentcount) AS total_commentcount,
        SUM(p.favoritecount) AS total_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS comment_on_posts_count,
        SUM(c.score) AS comment_score_on_posts_sum
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received_count,
        SUM(v.bountyamount) AS bounty_received_sum
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast_count,
        SUM(v.bountyamount) AS bounty_cast_sum
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
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_distinct_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_source AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS source_postlinks_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_target AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS target_postlinks_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
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
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(uc.comment_on_posts_count, 0) AS comment_on_posts_count,
    COALESCE(uc.comment_score_on_posts_sum, 0) AS comment_score_on_posts_sum,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.bounty_received_sum, 0) AS bounty_received_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.bounty_cast_sum, 0) AS bounty_cast_sum,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.tag_distinct_count, 0) AS tag_distinct_count,
    COALESCE(ups.source_postlinks_count, 0) AS source_postlinks_count,
    COALESCE(upt.target_postlinks_count, 0) AS target_postlinks_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN user_votes_received uvr ON u.id = uvr.user_id
LEFT JOIN user_votes_cast uvc ON u.id = uvc.user_id
LEFT JOIN user_badges ub ON u.id = ub.user_id
LEFT JOIN user_tags ut ON u.id = ut.user_id
LEFT JOIN user_postlinks_source ups ON u.id = ups.user_id
LEFT JOIN user_postlinks_target upt ON u.id = upt.user_id
LEFT JOIN user_posthistory uph ON u.id = uph.user_id
ORDER BY u.reputation DESC
LIMIT 100
