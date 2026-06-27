WITH vote_stats AS (
    SELECT
        votes.postid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votes.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(votes.bountyamount) AS total_bounty
    FROM votes
    GROUP BY votes.postid
),
post_user_stats AS (
    SELECT
        posts.id AS post_id,
        posts.posttypeid,
        posts.score,
        posts.viewcount,
        posts.answercount,
        posts.commentcount,
        posts.favoritecount,
        posts.owneruserid,
        posts.lasteditoruserid,
        COALESCE(vote_stats.vote_count, 0) AS vote_count,
        COALESCE(vote_stats.upvote_count, 0) AS upvote_count,
        COALESCE(vote_stats.downvote_count, 0) AS downvote_count,
        COALESCE(vote_stats.total_bounty, 0) AS total_bounty
    FROM posts
    LEFT JOIN vote_stats
        ON posts.id = vote_stats.postid
),
edited_posts AS (
    SELECT
        posts.lasteditoruserid AS editor_userid,
        COUNT(*) AS edited_posts
    FROM posts
    WHERE posts.lasteditoruserid IS NOT NULL
    GROUP BY posts.lasteditoruserid
)
SELECT
    users.id AS user_id,
    users.reputation,
    users.creationdate,
    COUNT(DISTINCT post_user_stats.post_id) AS owned_posts,
    COALESCE(edited_posts.edited_posts, 0) AS edited_posts,
    SUM(post_user_stats.score) AS total_score,
    AVG(post_user_stats.score) AS avg_score,
    SUM(post_user_stats.viewcount) AS total_views,
    SUM(post_user_stats.answercount) AS total_answers,
    SUM(post_user_stats.vote_count) AS total_votes_received,
    SUM(post_user_stats.total_bounty) AS total_bounty_received,
    COUNT(DISTINCT votes.id) AS votes_cast,
    SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_given,
    SUM(CASE WHEN votes.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_given
FROM users
LEFT JOIN post_user_stats
    ON users.id = post_user_stats.owneruserid
LEFT JOIN votes
    ON users.id = votes.userid
LEFT JOIN edited_posts
    ON users.id = edited_posts.editor_userid
GROUP BY
    users.id,
    users.reputation,
    users.creationdate,
    edited_posts.edited_posts
ORDER BY total_score DESC
LIMIT 10
