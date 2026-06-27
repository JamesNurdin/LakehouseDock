WITH user_posts AS (
    SELECT
        u.id AS user_id,
        p.id AS post_id,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount
    FROM users u
    JOIN posts p
        ON p.owneruserid = u.id
),
post_votes_received AS (
    SELECT
        p.owneruserid AS owner_user_id,
        v.id AS vote_id,
        v.votetypeid,
        v.bountyamount
    FROM votes v
    JOIN posts p
        ON v.postid = p.id
),
votes_cast AS (
    SELECT
        v.userid AS voter_user_id,
        v.id AS vote_id
    FROM votes v
),
post_edits AS (
    SELECT
        p.lasteditoruserid AS editor_user_id,
        p.id AS edited_post_id
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
),
post_history_entries AS (
    SELECT
        ph.userid AS history_user_id,
        ph.id AS history_id
    FROM posthistory ph
),
post_links_created AS (
    SELECT
        p.owneruserid AS owner_user_id,
        pl.id AS link_id
    FROM postlinks pl
    JOIN posts p
        ON pl.postid = p.id
),
post_links_inbound AS (
    SELECT
        p.owneruserid AS owner_user_id,
        pl.id AS inbound_link_id
    FROM postlinks pl
    JOIN posts p
        ON pl.relatedpostid = p.id
),
user_tag_excerpts AS (
    SELECT
        p.owneruserid AS owner_user_id,
        t.id AS tag_id,
        t."count" AS tag_excerpt_count
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    COUNT(DISTINCT up.post_id) AS authored_posts,
    COALESCE(SUM(up.score), 0) AS total_post_score,
    COALESCE(SUM(up.viewcount), 0) AS total_post_views,
    COALESCE(SUM(up.answercount), 0) AS total_answers,
    COALESCE(SUM(up.commentcount), 0) AS total_comments,
    COALESCE(SUM(up.favoritecount), 0) AS total_favorites,
    COUNT(DISTINCT pvr.vote_id) AS votes_received,
    COUNT(DISTINCT pvr.votetypeid) AS distinct_vote_types_received,
    COALESCE(SUM(pvr.bountyamount), 0) AS total_bounty_received,
    COUNT(DISTINCT vc.vote_id) AS votes_cast,
    COUNT(DISTINCT pe.edited_post_id) AS posts_edited,
    COUNT(DISTINCT ph.history_id) AS post_history_entries,
    COUNT(DISTINCT plc.link_id) AS post_links_created,
    COUNT(DISTINCT pli.inbound_link_id) AS inbound_links_to_posts,
    COALESCE(SUM(ute.tag_excerpt_count), 0) AS total_tag_excerpt_counts
FROM users u
LEFT JOIN user_posts up
    ON u.id = up.user_id
LEFT JOIN post_votes_received pvr
    ON u.id = pvr.owner_user_id
LEFT JOIN votes_cast vc
    ON u.id = vc.voter_user_id
LEFT JOIN post_edits pe
    ON u.id = pe.editor_user_id
LEFT JOIN post_history_entries ph
    ON u.id = ph.history_user_id
LEFT JOIN post_links_created plc
    ON u.id = plc.owner_user_id
LEFT JOIN post_links_inbound pli
    ON u.id = pli.owner_user_id
LEFT JOIN user_tag_excerpts ute
    ON u.id = ute.owner_user_id
GROUP BY
    u.id,
    u.reputation
ORDER BY total_post_score DESC
LIMIT 100
