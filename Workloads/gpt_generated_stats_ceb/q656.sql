WITH
    user_posts AS (
        SELECT
            posts.owneruserid AS owneruserid,
            COUNT(*) AS post_count,
            SUM(posts.score) AS total_post_score,
            SUM(posts.viewcount) AS total_view_count,
            SUM(posts.answercount) AS total_answer_count,
            SUM(posts.commentcount) AS total_post_comment_count,
            SUM(posts.favoritecount) AS total_favorite_count
        FROM posts
        GROUP BY posts.owneruserid
    ),
    user_edits AS (
        SELECT
            posts.lasteditoruserid AS lasteditoruserid,
            COUNT(*) AS edit_count,
            SUM(posts.score) AS total_edit_score
        FROM posts
        WHERE posts.lasteditoruserid IS NOT NULL
        GROUP BY posts.lasteditoruserid
    ),
    user_comments AS (
        SELECT
            comments.userid AS userid,
            COUNT(*) AS comment_count,
            SUM(comments.score) AS total_comment_score
        FROM comments
        GROUP BY comments.userid
    ),
    user_votes AS (
        SELECT
            votes.userid AS userid,
            COUNT(*) AS vote_count,
            SUM(COALESCE(votes.bountyamount, 0)) AS total_bounty_amount,
            COUNT(CASE WHEN votes.votetypeid = 1 THEN 1 END) AS upvote_count,
            COUNT(CASE WHEN votes.votetypeid = 2 THEN 1 END) AS downvote_count
        FROM votes
        GROUP BY votes.userid
    ),
    user_badges AS (
        SELECT
            badges.userid AS userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY badges.userid
    ),
    user_posthistory AS (
        SELECT
            posthistory.userid AS userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY posthistory.userid
    ),
    user_tags AS (
        SELECT
            posts.owneruserid AS owneruserid,
            COUNT(*) AS tag_count
        FROM tags
        JOIN posts
            ON tags.excerptpostid = posts.id
        GROUP BY posts.owneruserid
    )
SELECT
    users.id AS user_id,
    users.reputation,
    COALESCE(user_posts.post_count, 0) AS post_count,
    COALESCE(user_posts.total_post_score, 0) AS total_post_score,
    CASE WHEN COALESCE(user_posts.post_count, 0) = 0 THEN 0
         ELSE COALESCE(user_posts.total_post_score, 0) / COALESCE(user_posts.post_count, 1)
    END AS avg_post_score,
    COALESCE(user_posts.total_view_count, 0) AS total_view_count,
    COALESCE(user_posts.total_answer_count, 0) AS total_answer_count,
    COALESCE(user_posts.total_post_comment_count, 0) AS total_post_comment_count,
    COALESCE(user_posts.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(user_edits.edit_count, 0) AS edit_count,
    COALESCE(user_edits.total_edit_score, 0) AS total_edit_score,
    COALESCE(user_comments.comment_count, 0) AS comment_count,
    COALESCE(user_comments.total_comment_score, 0) AS total_comment_score,
    COALESCE(user_votes.vote_count, 0) AS vote_count,
    COALESCE(user_votes.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(user_votes.upvote_count, 0) AS upvote_count,
    COALESCE(user_votes.downvote_count, 0) AS downvote_count,
    COALESCE(user_badges.badge_count, 0) AS badge_count,
    COALESCE(user_posthistory.posthistory_count, 0) AS posthistory_count,
    COALESCE(user_tags.tag_count, 0) AS tag_count
FROM users
LEFT JOIN user_posts
    ON user_posts.owneruserid = users.id
LEFT JOIN user_edits
    ON user_edits.lasteditoruserid = users.id
LEFT JOIN user_comments
    ON user_comments.userid = users.id
LEFT JOIN user_votes
    ON user_votes.userid = users.id
LEFT JOIN user_badges
    ON user_badges.userid = users.id
LEFT JOIN user_posthistory
    ON user_posthistory.userid = users.id
LEFT JOIN user_tags
    ON user_tags.owneruserid = users.id
ORDER BY users.reputation DESC
LIMIT 100
