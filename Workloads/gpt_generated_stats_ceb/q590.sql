WITH
    posts_per_user AS (
        SELECT
            posts.owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(posts.score) AS total_post_score,
            SUM(posts.viewcount) AS total_views
        FROM posts
        GROUP BY posts.owneruserid
    ),
    comments_per_user AS (
        SELECT
            comments.userid AS userid,
            COUNT(*) AS comment_count,
            SUM(comments.score) AS total_comment_score
        FROM comments
        GROUP BY comments.userid
    ),
    votes_per_user AS (
        SELECT
            votes.userid AS userid,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votes.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
        FROM votes
        GROUP BY votes.userid
    ),
    badges_per_user AS (
        SELECT
            badges.userid AS userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY badges.userid
    ),
    posthistory_per_user AS (
        SELECT
            posthistory.userid AS userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY posthistory.userid
    ),
    edits_per_user AS (
        SELECT
            posts.lasteditoruserid AS userid,
            COUNT(*) AS edit_count
        FROM posts
        GROUP BY posts.lasteditoruserid
    ),
    tag_excerpts_per_user AS (
        SELECT
            posts.owneruserid AS userid,
            COUNT(*) AS tag_excerpt_count
        FROM tags
        JOIN posts
            ON tags.excerptpostid = posts.id
        GROUP BY posts.owneruserid
    ),
    postlinks_per_user AS (
        SELECT
            posts.owneruserid AS userid,
            COUNT(*) AS postlinks_count
        FROM postlinks
        JOIN posts
            ON postlinks.postid = posts.id
        GROUP BY posts.owneruserid
    )
SELECT
    users.id AS user_id,
    users.reputation,
    users.creationdate,
    COALESCE(posts_per_user.post_count, 0) AS post_count,
    COALESCE(posts_per_user.total_post_score, 0) AS total_post_score,
    COALESCE(posts_per_user.total_views, 0) AS total_views,
    COALESCE(comments_per_user.comment_count, 0) AS comment_count,
    COALESCE(comments_per_user.total_comment_score, 0) AS total_comment_score,
    COALESCE(votes_per_user.vote_count, 0) AS vote_count,
    COALESCE(votes_per_user.upvote_count, 0) AS upvote_count,
    COALESCE(votes_per_user.downvote_count, 0) AS downvote_count,
    COALESCE(badges_per_user.badge_count, 0) AS badge_count,
    COALESCE(posthistory_per_user.posthistory_count, 0) AS posthistory_count,
    COALESCE(edits_per_user.edit_count, 0) AS edit_count,
    COALESCE(tag_excerpts_per_user.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(postlinks_per_user.postlinks_count, 0) AS postlinks_count,
    (COALESCE(posts_per_user.post_count, 0) +
     COALESCE(comments_per_user.comment_count, 0) +
     COALESCE(votes_per_user.vote_count, 0) +
     COALESCE(badges_per_user.badge_count, 0) +
     COALESCE(posthistory_per_user.posthistory_count, 0) +
     COALESCE(edits_per_user.edit_count, 0) +
     COALESCE(tag_excerpts_per_user.tag_excerpt_count, 0) +
     COALESCE(postlinks_per_user.postlinks_count, 0)) AS total_activity
FROM users
LEFT JOIN posts_per_user
    ON posts_per_user.userid = users.id
LEFT JOIN comments_per_user
    ON comments_per_user.userid = users.id
LEFT JOIN votes_per_user
    ON votes_per_user.userid = users.id
LEFT JOIN badges_per_user
    ON badges_per_user.userid = users.id
LEFT JOIN posthistory_per_user
    ON posthistory_per_user.userid = users.id
LEFT JOIN edits_per_user
    ON edits_per_user.userid = users.id
LEFT JOIN tag_excerpts_per_user
    ON tag_excerpts_per_user.userid = users.id
LEFT JOIN postlinks_per_user
    ON postlinks_per_user.userid = users.id
ORDER BY total_activity DESC
LIMIT 10
