/*
  Analytical query: summary of user activity across posts, comments, votes, badges, tags,
  post‑history entries and post‑links. Shows the top 20 users by reputation.
*/
WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(score), 0) AS total_post_score,
        COALESCE(SUM(viewcount), 0) AS total_views
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(score), 0) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_count,
        COALESCE(SUM(votetypeid), 0) AS sum_vote_type
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p
        ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.sum_vote_type, 0) AS sum_vote_type,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ul.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN user_comments uc
    ON uc.user_id = u.id
LEFT JOIN user_votes uv
    ON uv.user_id = u.id
LEFT JOIN user_badges ub
    ON ub.user_id = u.id
LEFT JOIN user_tags ut
    ON ut.user_id = u.id
LEFT JOIN user_posthistory uph
    ON uph.user_id = u.id
LEFT JOIN user_postlinks ul
    ON ul.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 20
