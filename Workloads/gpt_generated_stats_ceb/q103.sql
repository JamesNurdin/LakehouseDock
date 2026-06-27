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
        COUNT(v.id) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY
        p.id,
        p.owneruserid,
        p.lasteditoruserid,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount
)
SELECT
    o.id AS owner_user_id,
    o.reputation AS owner_reputation,
    COUNT(pv.post_id) AS owned_posts,
    SUM(pv.score) AS total_score,
    AVG(pv.score) AS avg_score,
    SUM(pv.vote_count) AS total_votes_on_owned_posts,
    AVG(pv.vote_count) AS avg_votes_per_owned_post,
    SUM(pv.upvote_count) AS total_upvotes_on_owned_posts,
    SUM(pv.downvote_count) AS total_downvotes_on_owned_posts
FROM post_votes pv
JOIN users o
    ON pv.owneruserid = o.id
GROUP BY
    o.id,
    o.reputation
ORDER BY total_score DESC
LIMIT 10
