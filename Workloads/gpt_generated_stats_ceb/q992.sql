WITH post_votes AS (
    SELECT
        v.postid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes v
    GROUP BY v.postid
),
post_history AS (
    SELECT
        ph.posthistorytypeid AS postid,
        COUNT(*) AS history_event_count,
        COUNT(DISTINCT ph.userid) AS distinct_editors
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
post_links AS (
    SELECT
        pl.postid,
        COUNT(*) AS link_count
    FROM postlinks pl
    GROUP BY pl.postid
),
post_tags AS (
    SELECT
        t.excerptpostid AS postid,
        COUNT(*) AS tag_count
    FROM tags t
    GROUP BY t.excerptpostid
),
post_aggregated AS (
    SELECT
        p.id AS post_id,
        p.owneruserid AS owner_user_id,
        p.lasteditoruserid AS last_editor_user_id,
        p.score,
        p.viewcount,
        p.favoritecount,
        COALESCE(v.vote_count, 0) AS vote_count,
        COALESCE(ph.history_event_count, 0) AS history_event_count,
        COALESCE(pl.link_count, 0) AS link_count,
        COALESCE(tg.tag_count, 0) AS tag_count
    FROM posts p
    LEFT JOIN post_votes v ON v.postid = p.id
    LEFT JOIN post_history ph ON ph.postid = p.id
    LEFT JOIN post_links pl ON pl.postid = p.id
    LEFT JOIN post_tags tg ON tg.postid = p.id
),
user_votes_cast AS (
    SELECT
        v.userid,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
user_history_events AS (
    SELECT
        ph.userid,
        COUNT(*) AS history_events_contributed
    FROM posthistory ph
    GROUP BY ph.userid
),
user_posts_edited AS (
    SELECT
        p.lasteditoruserid AS editor_user_id,
        COUNT(*) AS posts_edited
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(pu.posts_owned, 0) AS posts_owned,
    COALESCE(pu.total_score, 0) AS total_score,
    COALESCE(pu.total_viewcount, 0) AS total_viewcount,
    COALESCE(pu.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(pu.total_votes_received, 0) AS total_votes_received,
    COALESCE(pu.total_history_events, 0) AS total_history_events,
    COALESCE(pu.total_links, 0) AS total_links,
    COALESCE(pu.total_tags, 0) AS total_tags,
    COALESCE(pe.posts_edited, 0) AS posts_edited,
    COALESCE(uv.votes_cast, 0) AS votes_cast,
    COALESCE(uv.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uv.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(uh.history_events_contributed, 0) AS history_events_contributed,
    u.upvotes AS user_upvotes,
    u.downvotes AS user_downvotes
FROM users u
LEFT JOIN (
    SELECT
        pa.owner_user_id,
        COUNT(*) AS posts_owned,
        SUM(pa.score) AS total_score,
        SUM(pa.viewcount) AS total_viewcount,
        SUM(pa.favoritecount) AS total_favoritecount,
        SUM(pa.vote_count) AS total_votes_received,
        SUM(pa.history_event_count) AS total_history_events,
        SUM(pa.link_count) AS total_links,
        SUM(pa.tag_count) AS total_tags
    FROM post_aggregated pa
    GROUP BY pa.owner_user_id
) pu ON pu.owner_user_id = u.id
LEFT JOIN user_votes_cast uv ON uv.userid = u.id
LEFT JOIN user_history_events uh ON uh.userid = u.id
LEFT JOIN user_posts_edited pe ON pe.editor_user_id = u.id
ORDER BY total_votes_received DESC
LIMIT 100
