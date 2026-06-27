WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(viewcount) AS avg_viewcount
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_last_edits AS (
    SELECT
        lasteditoruserid AS userid,
        COUNT(*) AS last_edit_count
    FROM posts
    GROUP BY lasteditoruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_post_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_posthistory_events AS (
    SELECT
        userid,
        COUNT(*) AS posthistory_event_count
    FROM posthistory
    GROUP BY userid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    CASE WHEN COALESCE(up.post_count, 0) > 0
         THEN up.total_post_score / up.post_count
         ELSE NULL END AS avg_post_score,
    COALESCE(up.avg_viewcount, 0) AS avg_viewcount,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.votes_cast, 0) AS votes_cast,
    COALESCE(upv.votes_received, 0) AS votes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ule.last_edit_count, 0) AS last_edit_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(uph.posthistory_event_count, 0) AS posthistory_event_count,
    COALESCE(upl.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up      ON u.id = up.userid
LEFT JOIN user_comments uc   ON u.id = uc.userid
LEFT JOIN user_votes_cast uv ON u.id = uv.userid
LEFT JOIN user_badges ub     ON u.id = ub.userid
LEFT JOIN user_last_edits ule ON u.id = ule.userid
LEFT JOIN user_tags ut       ON u.id = ut.userid
LEFT JOIN user_post_votes_received upv ON u.id = upv.userid
LEFT JOIN user_posthistory_events uph   ON u.id = uph.userid
LEFT JOIN user_postlinks upl            ON u.id = upl.userid
ORDER BY u.reputation DESC, post_count DESC
LIMIT 100
