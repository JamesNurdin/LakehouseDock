WITH
    users_base AS (
        SELECT id, reputation
        FROM users
    ),
    posts_agg AS (
        SELECT posts.owneruserid AS user_id,
               COUNT(*) AS post_count,
               SUM(posts.score) AS post_score_sum,
               AVG(posts.viewcount) AS post_viewcount_avg
        FROM posts
        GROUP BY posts.owneruserid
    ),
    comments_agg AS (
        SELECT comments.userid AS user_id,
               COUNT(*) AS comment_count,
               SUM(comments.score) AS comment_score_sum
        FROM comments
        GROUP BY comments.userid
    ),
    votes_cast_agg AS (
        SELECT votes.userid AS user_id,
               COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY votes.userid
    ),
    votes_received_agg AS (
        SELECT posts.owneruserid AS user_id,
               COUNT(*) AS votes_received_count
        FROM votes
        JOIN posts ON votes.postid = posts.id
        GROUP BY posts.owneruserid
    ),
    badges_agg AS (
        SELECT badges.userid AS user_id,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY badges.userid
    ),
    posthistory_agg AS (
        SELECT posthistory.userid AS user_id,
               COUNT(*) AS edit_count
        FROM posthistory
        GROUP BY posthistory.userid
    ),
    postlinks_agg AS (
        SELECT posts.owneruserid AS user_id,
               COUNT(*) AS link_count
        FROM postlinks
        JOIN posts ON postlinks.postid = posts.id
        GROUP BY posts.owneruserid
    )
SELECT
    users_base.id AS user_id,
    users_base.reputation,
    COALESCE(posts_agg.post_count, 0) AS post_count,
    COALESCE(posts_agg.post_score_sum, 0) AS post_score_sum,
    COALESCE(posts_agg.post_viewcount_avg, 0) AS post_viewcount_avg,
    COALESCE(comments_agg.comment_count, 0) AS comment_count,
    COALESCE(comments_agg.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(votes_cast_agg.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(votes_received_agg.votes_received_count, 0) AS votes_received_count,
    COALESCE(badges_agg.badge_count, 0) AS badge_count,
    COALESCE(posthistory_agg.edit_count, 0) AS edit_count,
    COALESCE(postlinks_agg.link_count, 0) AS link_count
FROM users_base
LEFT JOIN posts_agg ON users_base.id = posts_agg.user_id
LEFT JOIN comments_agg ON users_base.id = comments_agg.user_id
LEFT JOIN votes_cast_agg ON users_base.id = votes_cast_agg.user_id
LEFT JOIN votes_received_agg ON users_base.id = votes_received_agg.user_id
LEFT JOIN badges_agg ON users_base.id = badges_agg.user_id
LEFT JOIN posthistory_agg ON users_base.id = posthistory_agg.user_id
LEFT JOIN postlinks_agg ON users_base.id = postlinks_agg.user_id
ORDER BY users_base.reputation DESC
LIMIT 100
