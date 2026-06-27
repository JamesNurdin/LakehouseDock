WITH post_base AS (
    SELECT
        CAST(p.creationdate AS date) AS post_date,
        p.posttypeid,
        p.id AS post_id,
        p.score,
        p.viewcount,
        p.owneruserid
    FROM posts p
),
post_owner AS (
    SELECT
        pb.post_date,
        pb.posttypeid,
        COUNT(*) AS num_posts,
        SUM(pb.score) AS total_score,
        AVG(pb.score) AS avg_score,
        SUM(pb.viewcount) AS total_views,
        AVG(u.reputation) AS avg_owner_reputation
    FROM post_base pb
    LEFT JOIN users u
        ON pb.owneruserid = u.id
    GROUP BY pb.post_date, pb.posttypeid
),
comment_agg AS (
    SELECT
        CAST(p.creationdate AS date) AS post_date,
        p.posttypeid,
        COUNT(c.id) AS total_comments
    FROM posts p
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY CAST(p.creationdate AS date), p.posttypeid
),
vote_agg AS (
    SELECT
        CAST(p.creationdate AS date) AS post_date,
        p.posttypeid,
        COUNT(v.id) AS total_votes,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes
    FROM posts p
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY CAST(p.creationdate AS date), p.posttypeid
),
edit_agg AS (
    SELECT
        CAST(p.creationdate AS date) AS post_date,
        p.posttypeid,
        COUNT(ph.id) AS total_edits,
        COUNT(DISTINCT ph.userid) AS distinct_editors
    FROM posts p
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    GROUP BY CAST(p.creationdate AS date), p.posttypeid
),
link_out_agg AS (
    SELECT
        CAST(p.creationdate AS date) AS post_date,
        p.posttypeid,
        COUNT(pl.id) AS outgoing_links
    FROM posts p
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY CAST(p.creationdate AS date), p.posttypeid
),
link_in_agg AS (
    SELECT
        CAST(p.creationdate AS date) AS post_date,
        p.posttypeid,
        COUNT(pl.id) AS incoming_links
    FROM posts p
    LEFT JOIN postlinks pl
        ON pl.relatedpostid = p.id
    GROUP BY CAST(p.creationdate AS date), p.posttypeid
),
tag_agg AS (
    SELECT
        CAST(p.creationdate AS date) AS post_date,
        p.posttypeid,
        COUNT(t.id) AS tag_count
    FROM posts p
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY CAST(p.creationdate AS date), p.posttypeid
)
SELECT
    po.post_date,
    po.posttypeid,
    po.num_posts,
    po.total_score,
    po.avg_score,
    po.total_views,
    po.avg_owner_reputation,
    co.total_comments,
    vo.total_votes,
    vo.upvotes,
    vo.downvotes,
    eo.total_edits,
    eo.distinct_editors,
    lo.outgoing_links,
    li.incoming_links,
    ta.tag_count
FROM post_owner po
LEFT JOIN comment_agg co
    ON co.post_date = po.post_date AND co.posttypeid = po.posttypeid
LEFT JOIN vote_agg vo
    ON vo.post_date = po.post_date AND vo.posttypeid = po.posttypeid
LEFT JOIN edit_agg eo
    ON eo.post_date = po.post_date AND eo.posttypeid = po.posttypeid
LEFT JOIN link_out_agg lo
    ON lo.post_date = po.post_date AND lo.posttypeid = po.posttypeid
LEFT JOIN link_in_agg li
    ON li.post_date = po.post_date AND li.posttypeid = po.posttypeid
LEFT JOIN tag_agg ta
    ON ta.post_date = po.post_date AND ta.posttypeid = po.posttypeid
ORDER BY po.post_date DESC, po.posttypeid
