WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments_on_posts
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation, u.creationdate
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS outgoing_links
    FROM posts p
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tag_excerpts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(t.id) AS tag_excerpt_count
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(ph.id) AS posthistory_count,
        COUNT(DISTINCT ph.posthistorytypeid) AS distinct_history_type_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    up.total_views,
    up.total_answers,
    up.total_comments_on_posts,
    uc.comment_count,
    uc.total_comment_score,
    uvc.votes_cast,
    uvc.upvotes_cast,
    uvc.downvotes_cast,
    uvr.votes_received,
    uvr.upvotes_received,
    uvr.downvotes_received,
    upl.outgoing_links,
    ute.tag_excerpt_count,
    uph.posthistory_count,
    uph.distinct_history_type_count,
    ROW_NUMBER() OVER (ORDER BY up.total_post_score DESC) AS user_rank
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = up.user_id
LEFT JOIN user_votes_received uvr ON uvr.user_id = up.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = up.user_id
LEFT JOIN user_tag_excerpts ute ON ute.user_id = up.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = up.user_id
ORDER BY user_rank
LIMIT 100
