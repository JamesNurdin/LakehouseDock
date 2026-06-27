WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(id) AS post_count,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_viewcount,
        SUM(answercount) AS total_answercount,
        SUM(commentcount) AS total_commentcount,
        SUM(favoritecount) AS total_favoritecount
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(id) AS comment_count
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid AS user_id,
        COUNT(id) AS vote_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(id) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT
        userid AS user_id,
        COUNT(id) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_links AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(pl.id) AS link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ul.link_count, 0) AS link_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_links ul ON ul.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY post_count DESC, reputation DESC
LIMIT 10
