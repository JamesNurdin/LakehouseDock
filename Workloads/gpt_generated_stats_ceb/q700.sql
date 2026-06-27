WITH post_votes AS (
    SELECT
        p.id AS post_id,
        p.owneruserid AS owner_user_id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid,
        COUNT(v.id) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        COUNT(DISTINCT v.userid) AS distinct_voter_count
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY
        p.id,
        p.owneruserid,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid
),
post_tags AS (
    SELECT
        p.id AS post_id,
        COUNT(t.id) AS tag_count
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.id
),
post_analytics AS (
    SELECT
        pv.post_id,
        pv.owner_user_id,
        pv.posttypeid,
        pv.creationdate,
        pv.score,
        pv.viewcount,
        pv.answercount,
        pv.commentcount,
        pv.favoritecount,
        pv.lasteditoruserid,
        pv.vote_count,
        pv.upvote_count,
        pv.downvote_count,
        pv.distinct_voter_count,
        COALESCE(pt.tag_count, 0) AS tag_count,
        ROW_NUMBER() OVER (PARTITION BY pv.owner_user_id ORDER BY pv.score DESC) AS score_rank
    FROM post_votes pv
    LEFT JOIN post_tags pt ON pt.post_id = pv.post_id
)
SELECT
    pa.post_id,
    pa.owner_user_id,
    u.reputation,
    pa.score,
    pa.vote_count,
    pa.upvote_count,
    pa.downvote_count,
    pa.tag_count,
    pa.score_rank
FROM post_analytics pa
JOIN users u ON u.id = pa.owner_user_id
WHERE pa.score_rank = 1
ORDER BY pa.vote_count DESC
LIMIT 20
