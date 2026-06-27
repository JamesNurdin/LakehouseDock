WITH
    user_posts AS (
        SELECT
            users.id AS user_id,
            COUNT(posts.id) AS post_count,
            SUM(posts.score) AS post_score_sum,
            SUM(posts.viewcount) AS post_viewcount_sum,
            SUM(posts.favoritecount) AS post_favoritecount_sum
        FROM users
        LEFT JOIN posts ON posts.owneruserid = users.id
        GROUP BY users.id
    ),
    user_comments AS (
        SELECT
            users.id AS user_id,
            COUNT(comments.id) AS comment_count,
            SUM(comments.score) AS comment_score_sum
        FROM users
        LEFT JOIN comments ON comments.userid = users.id
        GROUP BY users.id
    ),
    user_votes_cast AS (
        SELECT
            users.id AS user_id,
            COUNT(votes.id) AS votes_cast_count,
            SUM(CASE WHEN votes.votetypeid = 1 THEN 1 WHEN votes.votetypeid = 2 THEN -1 ELSE 0 END) AS net_votes_cast
        FROM users
        LEFT JOIN votes ON votes.userid = users.id
        GROUP BY users.id
    ),
    user_votes_received AS (
        SELECT
            users.id AS user_id,
            COUNT(votes.id) AS votes_received_count,
            SUM(CASE WHEN votes.votetypeid = 1 THEN 1 WHEN votes.votetypeid = 2 THEN -1 ELSE 0 END) AS net_votes_received
        FROM users
        LEFT JOIN posts ON posts.owneruserid = users.id
        LEFT JOIN votes ON votes.postid = posts.id
        GROUP BY users.id
    ),
    user_badges AS (
        SELECT
            users.id AS user_id,
            COUNT(badges.id) AS badge_count
        FROM users
        LEFT JOIN badges ON badges.userid = users.id
        GROUP BY users.id
    ),
    user_edits AS (
        SELECT
            users.id AS user_id,
            COUNT(posts.id) AS edit_count
        FROM users
        LEFT JOIN posts ON posts.lasteditoruserid = users.id
        GROUP BY users.id
    ),
    user_posthistory AS (
        SELECT
            users.id AS user_id,
            COUNT(posthistory.id) AS posthistory_count
        FROM users
        LEFT JOIN posthistory ON posthistory.userid = users.id
        GROUP BY users.id
    ),
    user_tags AS (
        SELECT
            users.id AS user_id,
            COUNT(DISTINCT tags.id) AS tag_count
        FROM users
        LEFT JOIN posts ON posts.owneruserid = users.id
        LEFT JOIN tags ON tags.excerptpostid = posts.id
        GROUP BY users.id
    ),
    user_links AS (
        SELECT
            users.id AS user_id,
            COUNT(postlinks.id) AS postlink_count
        FROM users
        LEFT JOIN posts ON posts.owneruserid = users.id
        LEFT JOIN postlinks ON postlinks.postid = posts.id
        GROUP BY users.id
    )
SELECT
    users.id,
    users.reputation,
    users.creationdate,
    COALESCE(user_posts.post_count, 0) AS post_count,
    COALESCE(user_posts.post_score_sum, 0) AS post_score_sum,
    COALESCE(user_comments.comment_count, 0) AS comment_count,
    COALESCE(user_comments.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(user_votes_cast.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(user_votes_cast.net_votes_cast, 0) AS net_votes_cast,
    COALESCE(user_votes_received.votes_received_count, 0) AS votes_received_count,
    COALESCE(user_votes_received.net_votes_received, 0) AS net_votes_received,
    COALESCE(user_badges.badge_count, 0) AS badge_count,
    COALESCE(user_edits.edit_count, 0) AS edit_count,
    COALESCE(user_posthistory.posthistory_count, 0) AS posthistory_count,
    COALESCE(user_tags.tag_count, 0) AS tag_count,
    COALESCE(user_links.postlink_count, 0) AS postlink_count
FROM users
LEFT JOIN user_posts ON user_posts.user_id = users.id
LEFT JOIN user_comments ON user_comments.user_id = users.id
LEFT JOIN user_votes_cast ON user_votes_cast.user_id = users.id
LEFT JOIN user_votes_received ON user_votes_received.user_id = users.id
LEFT JOIN user_badges ON user_badges.user_id = users.id
LEFT JOIN user_edits ON user_edits.user_id = users.id
LEFT JOIN user_posthistory ON user_posthistory.user_id = users.id
LEFT JOIN user_tags ON user_tags.user_id = users.id
LEFT JOIN user_links ON user_links.user_id = users.id
ORDER BY net_votes_received DESC
LIMIT 10
