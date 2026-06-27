WITH user_posts AS (
    SELECT
        owneruserid,
        COUNT(*) AS post_count,
        COUNT(CASE WHEN posttypeid = 2 THEN 1 END) AS answer_count,
        SUM(score) AS total_post_score,
        SUM(viewcount) AS total_post_views
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
user_votes_received AS (
    SELECT
        p.owneruserid,
        COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT
        userid,
        COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_last_edits AS (
    SELECT
        lasteditoruserid,
        COUNT(*) AS last_edit_count
    FROM posts
    GROUP BY lasteditoruserid
)
SELECT
    u.id,
    u.reputation,
    COALESCE(p.post_count, 0)            AS post_count,
    COALESCE(p.answer_count, 0)          AS answer_count,
    COALESCE(p.total_post_score, 0)      AS total_post_score,
    COALESCE(p.total_post_views, 0)      AS total_post_views,
    COALESCE(c.comment_count, 0)         AS comment_count,
    COALESCE(vc.votes_cast, 0)           AS votes_cast,
    COALESCE(vr.votes_received, 0)       AS votes_received,
    COALESCE(b.badge_count, 0)           AS badge_count,
    COALESCE(e.edit_count, 0)            AS edit_count,
    COALESCE(le.last_edit_count, 0)      AS last_edit_count,
    (COALESCE(p.post_count, 0) +
     COALESCE(c.comment_count, 0) +
     COALESCE(vc.votes_cast, 0) +
     COALESCE(b.badge_count, 0))        AS activity_score
FROM users u
LEFT JOIN user_posts          p  ON u.id = p.owneruserid
LEFT JOIN user_comments       c  ON u.id = c.userid
LEFT JOIN user_votes_cast     vc ON u.id = vc.userid
LEFT JOIN user_votes_received vr ON u.id = vr.owneruserid
LEFT JOIN user_badges         b  ON u.id = b.userid
LEFT JOIN user_edits          e  ON u.id = e.userid
LEFT JOIN user_last_edits     le ON u.id = le.lasteditoruserid
ORDER BY activity_score DESC
LIMIT 100
