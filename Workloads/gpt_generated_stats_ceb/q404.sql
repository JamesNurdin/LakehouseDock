WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS total_score,
        SUM(viewcount) AS total_views,
        SUM(answercount) AS total_answers,
        SUM(commentcount) AS total_comments,
        SUM(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT
        lasteditoruserid AS userid,
        COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
),
user_votes AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast,
        SUM(bountyamount) AS total_bounty
    FROM votes
    GROUP BY userid
),
user_history AS (
    SELECT
        userid,
        COUNT(*) AS history_entries
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    u.views AS user_views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_score, 0) AS total_post_score,
    COALESCE(p.total_views, 0) AS total_post_views,
    COALESCE(p.total_answers, 0) AS total_post_answers,
    COALESCE(p.total_comments, 0) AS total_post_comments,
    COALESCE(p.total_favorites, 0) AS total_post_favorites,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(v.votes_cast, 0) AS votes_cast,
    COALESCE(v.total_bounty, 0) AS total_bounty_cast,
    COALESCE(h.history_entries, 0) AS history_entries,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN COALESCE(p.total_score, 0) / NULLIF(p.post_count, 0) ELSE 0 END AS avg_score_per_post
FROM users u
LEFT JOIN user_posts p ON u.id = p.userid
LEFT JOIN user_edits e ON u.id = e.userid
LEFT JOIN user_votes v ON u.id = v.userid
LEFT JOIN user_history h ON u.id = h.userid
ORDER BY total_post_score DESC
LIMIT 100
