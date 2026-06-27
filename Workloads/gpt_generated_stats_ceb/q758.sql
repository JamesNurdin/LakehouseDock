-- User activity summary across posts, comments, votes, badges, edits, links, history, and tag excerpts
WITH user_posts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS total_score,
           AVG(score) AS avg_score
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid,
           COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT lasteditoruserid AS userid,
           COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_post_comments AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS comments_on_posts
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_post_links AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS post_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
    UNION ALL
    SELECT p.owneruserid AS userid,
           COUNT(*) AS post_links
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
),
user_post_history AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS post_history_entries
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_tag_excerpts AS (
    SELECT p.owneruserid AS userid,
           COUNT(*) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_score, 0) AS total_post_score,
       COALESCE(up.avg_score, 0) AS avg_post_score,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ue.edit_count, 0) AS edit_count,
       COALESCE(upc.comments_on_posts, 0) AS comments_on_posts,
       COALESCE(pl.total_links, 0) AS post_links,
       COALESCE(ph.post_history_entries, 0) AS post_history_entries,
       COALESCE(ute.tag_excerpt_count, 0) AS tag_excerpt_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_post_comments upc ON upc.userid = u.id
LEFT JOIN (
    SELECT userid, SUM(post_links) AS total_links
    FROM user_post_links
    GROUP BY userid
) pl ON pl.userid = u.id
LEFT JOIN user_post_history ph ON ph.userid = u.id
LEFT JOIN user_tag_excerpts ute ON ute.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
