WITH post_base AS (
    SELECT
        p.id AS post_id,
        p.owneruserid,
        p.score,
        p.viewcount,
        p.creationdate
    FROM posts p
),
comment_agg AS (
    SELECT
        c.postid,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.postid
),
vote_agg AS (
    SELECT
        v.postid,
        COUNT(*) AS vote_count
    FROM votes v
    GROUP BY v.postid
),
owner_badge_agg AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
tag_agg AS (
    SELECT
        t.excerptpostid AS post_id,
        COUNT(*) AS tag_count
    FROM tags t
    GROUP BY t.excerptpostid
),
posthistory_agg AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS history_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
owner_rep AS (
    SELECT
        u.id AS user_id,
        u.reputation
    FROM users u
)
SELECT
    pb.post_id,
    pb.score,
    pb.viewcount,
    pb.creationdate,
    orp.reputation AS owner_reputation,
    COALESCE(ca.comment_count, 0) AS comment_count,
    COALESCE(va.vote_count, 0) AS vote_count,
    COALESCE(ob.badge_count, 0) AS owner_badge_count,
    COALESCE(ta.tag_count, 0) AS tag_count,
    COALESCE(pha.history_count, 0) AS history_count
FROM post_base pb
LEFT JOIN comment_agg ca ON pb.post_id = ca.postid
LEFT JOIN vote_agg va ON pb.post_id = va.postid
LEFT JOIN owner_badge_agg ob ON pb.owneruserid = ob.user_id
LEFT JOIN tag_agg ta ON pb.post_id = ta.post_id
LEFT JOIN posthistory_agg pha ON pb.post_id = pha.post_id
LEFT JOIN owner_rep orp ON pb.owneruserid = orp.user_id
ORDER BY pb.score DESC
LIMIT 20
