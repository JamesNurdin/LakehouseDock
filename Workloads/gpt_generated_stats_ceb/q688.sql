WITH post_base AS (
    SELECT
        id,
        posttypeid,
        creationdate,
        score,
        viewcount,
        owneruserid,
        lasteditoruserid
    FROM posts
),
owner_rep AS (
    SELECT
        p.id AS postid,
        u.reputation AS owner_reputation
    FROM post_base p
    JOIN users u ON p.owneruserid = u.id
),
editor_rep AS (
    SELECT
        p.id AS postid,
        u.reputation AS editor_reputation
    FROM post_base p
    JOIN users u ON p.lasteditoruserid = u.id
),
comment_agg AS (
    SELECT
        c.postid,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum
    FROM comments c
    GROUP BY c.postid
),
vote_agg AS (
    SELECT
        v.postid,
        COUNT(*) AS vote_count,
        COALESCE(SUM(v.votetypeid), 0) AS vote_type_sum
    FROM votes v
    GROUP BY v.postid
),
outgoing_links_agg AS (
    SELECT
        pl.postid,
        COUNT(*) AS outgoing_links_count
    FROM postlinks pl
    GROUP BY pl.postid
),
incoming_links_agg AS (
    SELECT
        pl.relatedpostid AS postid,
        COUNT(*) AS incoming_links_count
    FROM postlinks pl
    GROUP BY pl.relatedpostid
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    p.creationdate,
    p.score AS post_score,
    p.viewcount,
    p.owneruserid,
    o.owner_reputation,
    p.lasteditoruserid,
    e.editor_reputation,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(va.vote_count, 0) AS vote_count,
    COALESCE(va.vote_type_sum, 0) AS vote_type_sum,
    COALESCE(ola.outgoing_links_count, 0) AS outgoing_links_count,
    COALESCE(ila.incoming_links_count, 0) AS incoming_links_count,
    (COALESCE(ca.comment_score_sum, 0) + COALESCE(va.vote_type_sum, 0) + COALESCE(ola.outgoing_links_count, 0) + COALESCE(ila.incoming_links_count, 0)) AS engagement_score
FROM post_base p
LEFT JOIN owner_rep o ON p.id = o.postid
LEFT JOIN editor_rep e ON p.id = e.postid
LEFT JOIN comment_agg ca ON p.id = ca.postid
LEFT JOIN vote_agg va ON p.id = va.postid
LEFT JOIN outgoing_links_agg ola ON p.id = ola.postid
LEFT JOIN incoming_links_agg ila ON p.id = ila.postid
WHERE p.viewcount > 1000
ORDER BY engagement_score DESC
LIMIT 100
