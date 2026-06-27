WITH
    user_posts AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(*) AS total_posts,
            SUM(posts.score) AS total_post_score,
            AVG(posts.score) AS avg_post_score
        FROM posts
        GROUP BY posts.owneruserid
    ),
    user_comments AS (
        SELECT
            comments.userid AS user_id,
            COUNT(*) AS total_comments,
            SUM(comments.score) AS total_comment_score,
            AVG(comments.score) AS avg_comment_score
        FROM comments
        GROUP BY comments.userid
    ),
    user_votes_cast AS (
        SELECT
            votes.userid AS user_id,
            COUNT(*) AS total_votes_cast,
            SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
            SUM(CASE WHEN votes.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM votes
        GROUP BY votes.userid
    ),
    user_votes_received AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(votes.id) AS total_votes_received,
            SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
            SUM(CASE WHEN votes.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
        FROM votes
        JOIN posts ON votes.postid = posts.id
        GROUP BY posts.owneruserid
    ),
    user_badges AS (
        SELECT
            badges.userid AS user_id,
            COUNT(*) AS total_badges
        FROM badges
        GROUP BY badges.userid
    ),
    user_edits AS (
        SELECT
            posthistory.userid AS user_id,
            COUNT(*) AS total_edits
        FROM posthistory
        GROUP BY posthistory.userid
    ),
    user_edits_on_posts AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(*) AS total_edits_on_posts
        FROM posthistory
        JOIN posts ON posthistory.posthistorytypeid = posts.id
        GROUP BY posts.owneruserid
    ),
    user_tag_excerpts AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(DISTINCT tags.id) AS total_tag_excerpts
        FROM tags
        JOIN posts ON tags.excerptpostid = posts.id
        GROUP BY posts.owneruserid
    ),
    user_postlinks_outgoing AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(*) AS outgoing_links
        FROM postlinks
        JOIN posts ON postlinks.postid = posts.id
        GROUP BY posts.owneruserid
    ),
    user_postlinks_incoming AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(*) AS incoming_links
        FROM postlinks
        JOIN posts ON postlinks.relatedpostid = posts.id
        GROUP BY posts.owneruserid
    )
SELECT
    users.id AS user_id,
    users.reputation,
    COALESCE(user_posts.total_posts, 0) AS total_posts,
    COALESCE(user_posts.total_post_score, 0) AS total_post_score,
    COALESCE(user_posts.avg_post_score, 0) AS avg_post_score,
    COALESCE(user_comments.total_comments, 0) AS total_comments,
    COALESCE(user_comments.total_comment_score, 0) AS total_comment_score,
    COALESCE(user_comments.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(user_votes_cast.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(user_votes_cast.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(user_votes_cast.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(user_votes_received.total_votes_received, 0) AS total_votes_received,
    COALESCE(user_votes_received.upvotes_received, 0) AS upvotes_received,
    COALESCE(user_votes_received.downvotes_received, 0) AS downvotes_received,
    COALESCE(user_badges.total_badges, 0) AS total_badges,
    COALESCE(user_edits.total_edits, 0) AS total_edits,
    COALESCE(user_edits_on_posts.total_edits_on_posts, 0) AS total_edits_on_posts,
    COALESCE(user_tag_excerpts.total_tag_excerpts, 0) AS total_tag_excerpts,
    COALESCE(user_postlinks_outgoing.outgoing_links, 0) AS outgoing_links,
    COALESCE(user_postlinks_incoming.incoming_links, 0) AS incoming_links
FROM users
LEFT JOIN user_posts ON users.id = user_posts.user_id
LEFT JOIN user_comments ON users.id = user_comments.user_id
LEFT JOIN user_votes_cast ON users.id = user_votes_cast.user_id
LEFT JOIN user_votes_received ON users.id = user_votes_received.user_id
LEFT JOIN user_badges ON users.id = user_badges.user_id
LEFT JOIN user_edits ON users.id = user_edits.user_id
LEFT JOIN user_edits_on_posts ON users.id = user_edits_on_posts.user_id
LEFT JOIN user_tag_excerpts ON users.id = user_tag_excerpts.user_id
LEFT JOIN user_postlinks_outgoing ON users.id = user_postlinks_outgoing.user_id
LEFT JOIN user_postlinks_incoming ON users.id = user_postlinks_incoming.user_id
ORDER BY users.reputation DESC
LIMIT 100
