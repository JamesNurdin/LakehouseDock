WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS posts_created,
        SUM(score) AS total_post_score,
        SUM(viewcount) AS total_post_views,
        SUM(answercount) AS total_answers,
        SUM(commentcount) AS total_comments_on_posts,
        SUM(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comments_made,
        SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast,
        SUM(CASE WHEN votetypeid = 4 THEN bountyamount ELSE 0 END) AS total_bounty_awarded
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badges_earned
    FROM badges
    GROUP BY userid
),
user_tag_excerpts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS tag_excerpts
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT
        userid,
        COUNT(*) AS posthistory_events
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.posts_created, 0) AS posts_created,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_post_views, 0) AS total_post_views,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(p.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(p.total_favorites, 0) AS total_favorites,
    COALESCE(c.comments_made, 0) AS comments_made,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.votes_cast, 0) AS votes_cast,
    COALESCE(v.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(v.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(v.total_bounty_awarded, 0) AS total_bounty_awarded,
    COALESCE(b.badges_earned, 0) AS badges_earned,
    COALESCE(t.tag_excerpts, 0) AS tag_excerpts,
    COALESCE(ph.posthistory_events, 0) AS posthistory_events
FROM users u
LEFT JOIN user_posts p ON p.userid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes v ON v.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_tag_excerpts t ON t.userid = u.id
LEFT JOIN user_posthistory ph ON ph.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
