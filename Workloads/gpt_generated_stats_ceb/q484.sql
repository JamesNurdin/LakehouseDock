WITH post_votes AS (
    SELECT
        p.id AS post_id,
        p.owneruserid,
        p.lasteditoruserid,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        v.id AS vote_id,
        v.votetypeid,
        v.userid AS voter_userid
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
)
SELECT
    p.owneruserid AS owner_user_id,
    owner_u.reputation AS owner_reputation,
    COUNT(DISTINCT p.post_id) AS num_posts,
    SUM(p.score) AS total_post_score,
    SUM(p.viewcount) AS total_views,
    SUM(p.answercount) AS total_answers,
    COUNT(p.vote_id) AS total_votes,
    SUM(CASE WHEN p.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes,
    SUM(CASE WHEN p.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes,
    AVG(voter_u.reputation) AS avg_voter_reputation
FROM post_votes p
JOIN users owner_u
    ON p.owneruserid = owner_u.id
LEFT JOIN users voter_u
    ON p.voter_userid = voter_u.id
GROUP BY p.owneruserid, owner_u.reputation
ORDER BY total_votes DESC
LIMIT 10
