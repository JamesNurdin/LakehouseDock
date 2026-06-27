WITH tag_posts AS (
    SELECT
        t.id AS tag_id,
        t.count AS tag_count,
        p.id AS post_id,
        p.score AS post_score,
        p.owneruserid AS owner_user_id,
        p.lasteditoruserid AS last_editor_user_id
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
),
post_owner_rep AS (
    SELECT
        tp.tag_id,
        tp.tag_count,
        tp.post_id,
        tp.post_score,
        u.reputation AS owner_reputation,
        tp.last_editor_user_id
    FROM tag_posts tp
    JOIN users u
        ON tp.owner_user_id = u.id
),
vote_agg AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS total_votes,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        COUNT(DISTINCT v.userid) AS distinct_voter_count
    FROM votes v
    GROUP BY v.postid
),
posthistory_agg AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS edit_count,
        COUNT(DISTINCT ph.userid) AS distinct_editor_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
link_outbound_agg AS (
    SELECT
        pl.postid AS post_id,
        COUNT(*) AS outbound_link_count
    FROM postlinks pl
    GROUP BY pl.postid
),
link_inbound_agg AS (
    SELECT
        pl.relatedpostid AS post_id,
        COUNT(*) AS inbound_link_count
    FROM postlinks pl
    GROUP BY pl.relatedpostid
)
SELECT
    po.tag_id,
    po.tag_count,
    po.post_id,
    po.post_score,
    po.owner_reputation,
    COALESCE(v.total_votes, 0) AS total_votes,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(v.distinct_voter_count, 0) AS distinct_voter_count,
    COALESCE(ph.edit_count, 0) AS edit_count,
    COALESCE(ph.distinct_editor_count, 0) AS distinct_editor_count,
    COALESCE(lo.outbound_link_count, 0) AS outbound_link_count,
    COALESCE(li.inbound_link_count, 0) AS inbound_link_count
FROM post_owner_rep po
LEFT JOIN vote_agg v
    ON po.post_id = v.post_id
LEFT JOIN posthistory_agg ph
    ON po.post_id = ph.post_id
LEFT JOIN link_outbound_agg lo
    ON po.post_id = lo.post_id
LEFT JOIN link_inbound_agg li
    ON po.post_id = li.post_id
ORDER BY po.owner_reputation DESC
LIMIT 100
