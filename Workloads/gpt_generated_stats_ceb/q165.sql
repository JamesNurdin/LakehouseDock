WITH post_vote_stats AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.owneruserid,
        p.lasteditoruserid,
        COUNT(v.id) AS total_votes,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS up_votes,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS down_votes,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) -
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS net_votes
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY
        p.id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.owneruserid,
        p.lasteditoruserid
),
owner_user AS (
    SELECT
        u.id AS user_id,
        u.reputation AS owner_reputation,
        u.creationdate AS owner_creationdate,
        u.views AS owner_views,
        u.upvotes AS owner_upvotes,
        u.downvotes AS owner_downvotes
    FROM users u
),
editor_user AS (
    SELECT
        u.id AS user_id,
        u.reputation AS editor_reputation,
        u.creationdate AS editor_creationdate,
        u.views AS editor_views,
        u.upvotes AS editor_upvotes,
        u.downvotes AS editor_downvotes
    FROM users u
)
SELECT
    pvs.post_id,
    pvs.posttypeid,
    pvs.creationdate,
    pvs.score,
    pvs.answercount,
    pvs.commentcount,
    pvs.favoritecount,
    pvs.total_votes,
    pvs.up_votes,
    pvs.down_votes,
    pvs.net_votes,
    ou.owner_reputation,
    eu.editor_reputation,
    ROW_NUMBER() OVER (PARTITION BY pvs.posttypeid ORDER BY pvs.net_votes DESC) AS rank_within_type
FROM post_vote_stats pvs
LEFT JOIN owner_user ou ON ou.user_id = pvs.owneruserid
LEFT JOIN editor_user eu ON eu.user_id = pvs.lasteditoruserid
WHERE pvs.net_votes IS NOT NULL
ORDER BY pvs.net_votes DESC
LIMIT 10
