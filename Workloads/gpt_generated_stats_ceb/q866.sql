/*
   Analytical summary of user activity across the Stack Exchange dataset.
   For each user we compute counts and aggregates of posts, edits, comments,
   votes cast and received, badges, tags used, and post‑history entries.
*/
WITH
    user_posts AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(posts.id) AS post_count,
            SUM(posts.score) AS total_post_score,
            AVG(posts.score) AS avg_post_score,
            MAX(posts.creationdate) AS latest_post_date
        FROM posts
        GROUP BY posts.owneruserid
    ),
    user_edits AS (
        SELECT
            posts.lasteditoruserid AS user_id,
            COUNT(posts.id) AS edit_count
        FROM posts
        GROUP BY posts.lasteditoruserid
    ),
    user_comments AS (
        SELECT
            comments.userid AS user_id,
            COUNT(comments.id) AS comment_count,
            SUM(comments.score) AS comment_score_sum
        FROM comments
        GROUP BY comments.userid
    ),
    user_votes_cast AS (
        SELECT
            votes.userid AS user_id,
            COUNT(votes.id) AS votes_cast_count
        FROM votes
        GROUP BY votes.userid
    ),
    user_votes_received AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(votes.id) AS votes_received_count
        FROM votes
        JOIN posts
            ON votes.postid = posts.id
        GROUP BY posts.owneruserid
    ),
    user_badges AS (
        SELECT
            badges.userid AS user_id,
            COUNT(badges.id) AS badge_count
        FROM badges
        GROUP BY badges.userid
    ),
    user_tags AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(DISTINCT tags.id) AS tag_count
        FROM tags
        JOIN posts
            ON tags.excerptpostid = posts.id
        GROUP BY posts.owneruserid
    ),
    user_posthistory AS (
        SELECT
            posthistory.userid AS user_id,
            COUNT(posthistory.id) AS posthistory_count
        FROM posthistory
        GROUP BY posthistory.userid
    )
SELECT
    users.id AS user_id,
    users.reputation,
    users.creationdate,
    users.views,
    users.upvotes,
    users.downvotes,
    COALESCE(user_posts.post_count, 0) AS post_count,
    COALESCE(user_posts.total_post_score, 0) AS total_post_score,
    COALESCE(user_posts.avg_post_score, 0) AS avg_post_score,
    user_posts.latest_post_date,
    COALESCE(user_edits.edit_count, 0) AS edit_count,
    COALESCE(user_comments.comment_count, 0) AS comment_count,
    COALESCE(user_comments.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(user_votes_cast.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(user_votes_received.votes_received_count, 0) AS votes_received_count,
    COALESCE(user_badges.badge_count, 0) AS badge_count,
    COALESCE(user_tags.tag_count, 0) AS tag_count,
    COALESCE(user_posthistory.posthistory_count, 0) AS posthistory_count
FROM users
LEFT JOIN user_posts
    ON users.id = user_posts.user_id
LEFT JOIN user_edits
    ON users.id = user_edits.user_id
LEFT JOIN user_comments
    ON users.id = user_comments.user_id
LEFT JOIN user_votes_cast
    ON users.id = user_votes_cast.user_id
LEFT JOIN user_votes_received
    ON users.id = user_votes_received.user_id
LEFT JOIN user_badges
    ON users.id = user_badges.user_id
LEFT JOIN user_tags
    ON users.id = user_tags.user_id
LEFT JOIN user_posthistory
    ON users.id = user_posthistory.user_id
ORDER BY users.reputation DESC
LIMIT 100
