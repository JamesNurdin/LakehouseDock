WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_posts,
        SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers,
        SUM(p.score) AS total_post_score,
        MIN(p.creationdate) AS first_post_date,
        MAX(p.creationdate) AS last_post_date
    FROM posts p
    GROUP BY p.owneruserid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast,
        COUNT(DISTINCT v.postid) AS distinct_posts_voted
    FROM votes v
    GROUP BY v.userid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS total_comments,
        SUM(c.score) AS total_comment_score,
        MIN(c.creationdate) AS first_comment_date
    FROM comments c
    GROUP BY c.userid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS total_badges
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS total_edits,
        COUNT(DISTINCT ph.postid) AS distinct_posts_edited
    FROM posthistory ph
    GROUP BY ph.userid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS total_post_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tags
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_questions, 0) AS total_questions,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    up.first_post_date,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.distinct_posts_voted, 0) AS distinct_posts_voted,
    COALESCE(uc.total_comments, 0) AS total_comments,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    uc.first_comment_date,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(uph.total_edits, 0) AS total_edits,
    COALESCE(uph.distinct_posts_edited, 0) AS distinct_posts_edited,
    COALESCE(up_links.total_post_links, 0) AS total_post_links,
    COALESCE(ut.distinct_tags, 0) AS distinct_tags
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_postlinks up_links ON up_links.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
WHERE u.reputation > 1000
ORDER BY total_posts DESC, votes_received DESC
LIMIT 100
