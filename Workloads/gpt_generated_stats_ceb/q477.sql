WITH tag_posts AS (
    SELECT
        t.id AS tag_id,
        p.id AS post_id,
        p.owneruserid AS owner_user_id,
        p.score AS post_score,
        p.viewcount AS post_viewcount,
        p.commentcount AS post_commentcount
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
),
post_owner_info AS (
    SELECT
        tp.tag_id,
        tp.post_id,
        tp.post_score,
        tp.post_viewcount,
        tp.post_commentcount,
        u.reputation AS owner_reputation,
        u.id AS owner_user_id
    FROM tag_posts tp
    JOIN users u
        ON tp.owner_user_id = u.id
),
owner_badge_counts AS (
    SELECT
        b.userid AS user_id,
        COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
post_owner_badge AS (
    SELECT
        poi.tag_id,
        poi.post_id,
        poi.post_score,
        poi.post_viewcount,
        poi.post_commentcount,
        poi.owner_reputation,
        poi.owner_user_id,
        COALESCE(obc.badge_count, 0) AS owner_badge_count
    FROM post_owner_info poi
    LEFT JOIN owner_badge_counts obc
        ON poi.owner_user_id = obc.user_id
),
post_vote_counts AS (
    SELECT
        v.postid AS post_id,
        COUNT(v.id) AS vote_count
    FROM votes v
    GROUP BY v.postid
),
post_edit_counts AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(ph.id) AS edit_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
post_full AS (
    SELECT
        pob.tag_id,
        pob.post_id,
        pob.post_score,
        pob.post_viewcount,
        pob.post_commentcount,
        pob.owner_reputation,
        pob.owner_badge_count,
        COALESCE(pvc.vote_count, 0) AS vote_count,
        COALESCE(pec.edit_count, 0) AS edit_count
    FROM post_owner_badge pob
    LEFT JOIN post_vote_counts pvc
        ON pob.post_id = pvc.post_id
    LEFT JOIN post_edit_counts pec
        ON pob.post_id = pec.post_id
)
SELECT
    pf.tag_id,
    COUNT(pf.post_id) AS post_count,
    AVG(pf.post_score) AS avg_post_score,
    SUM(pf.post_viewcount) AS total_viewcount,
    SUM(pf.post_commentcount) AS total_commentcount,
    AVG(pf.owner_reputation) AS avg_owner_reputation,
    SUM(pf.owner_badge_count) AS total_owner_badges,
    SUM(pf.vote_count) AS total_votes,
    SUM(pf.edit_count) AS total_edits
FROM post_full pf
GROUP BY pf.tag_id
ORDER BY total_votes DESC
LIMIT 10
