WITH post_votes AS (
    SELECT
        p.id AS post_id,
        p.owneruserid,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        v.id AS vote_id,
        v.votetypeid,
        v.bountyamount,
        v.userid AS voter_user_id
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COUNT(DISTINCT pv.post_id) AS total_posts,
    COALESCE(SUM(pv.score), 0) AS total_post_score,
    COALESCE(AVG(pv.score), 0) AS avg_post_score,
    COALESCE(SUM(pv.viewcount), 0) AS total_post_views,
    COALESCE(SUM(pv.answercount), 0) AS total_answers,
    COALESCE(SUM(pv.commentcount), 0) AS total_comments,
    COALESCE(SUM(pv.favoritecount), 0) AS total_favorites,
    COUNT(pv.vote_id) AS total_votes_received,
    COUNT(DISTINCT pv.voter_user_id) AS distinct_voters,
    SUM(CASE WHEN pv.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
    SUM(CASE WHEN pv.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count,
    COALESCE(SUM(pv.bountyamount), 0) AS total_bounty_amount_received
FROM post_votes pv
JOIN users u ON u.id = pv.owneruserid
GROUP BY
    u.id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes
ORDER BY total_votes_received DESC
LIMIT 10
