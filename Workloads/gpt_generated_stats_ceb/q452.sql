WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(answercount) AS total_answers,
        SUM(commentcount) AS total_comments_on_posts
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid,
        COUNT(*) AS vote_cast_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count
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
user_edits AS (
    SELECT
        userid,
        COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_post_edits AS (
    SELECT
        u.id AS userid,
        COUNT(*) AS edits_on_user_posts
    FROM users u
    JOIN posts p ON p.owneruserid = u.id
    JOIN posthistory ph ON ph.posthistorytypeid = p.id
    GROUP BY u.id
),
user_post_links AS (
    SELECT
        u.id AS userid,
        COUNT(*) AS post_links_created
    FROM users u
    JOIN posts p ON p.owneruserid = u.id
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS userid,
        COUNT(*) AS tag_count_on_user_posts
    FROM users u
    JOIN posts p ON p.owneruserid = u.id
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(p.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(v.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(v.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(pe.edits_on_user_posts, 0) AS edits_on_user_posts,
    COALESCE(pl.post_links_created, 0) AS post_links_created,
    COALESCE(tg.tag_count_on_user_posts, 0) AS tag_count_on_user_posts
FROM users u
LEFT JOIN user_posts p ON u.id = p.userid
LEFT JOIN user_comments c ON u.id = c.userid
LEFT JOIN user_votes v ON u.id = v.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_edits e ON u.id = e.userid
LEFT JOIN user_post_edits pe ON u.id = pe.userid
LEFT JOIN user_post_links pl ON u.id = pl.userid
LEFT JOIN user_tags tg ON u.id = tg.userid
ORDER BY u.reputation DESC
LIMIT 100
