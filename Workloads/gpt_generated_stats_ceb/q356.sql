WITH post_with_user_info AS (
    SELECT
        p.id AS post_id,
        p.score,
        p.viewcount,
        p.answercount,
        p.owneruserid,
        p.lasteditoruserid,
        o.reputation AS owner_reputation,
        e.reputation AS editor_reputation
    FROM posts p
    LEFT JOIN users o ON p.owneruserid = o.id
    LEFT JOIN users e ON p.lasteditoruserid = e.id
),

tag_posts AS (
    SELECT
        t.id AS tag_id,
        pw.post_id,
        pw.score,
        pw.viewcount,
        pw.answercount,
        pw.owneruserid,
        pw.lasteditoruserid,
        pw.owner_reputation,
        pw.editor_reputation
    FROM tags t
    JOIN post_with_user_info pw ON t.excerptpostid = pw.post_id
),

post_links_agg AS (
    SELECT
        pl.postid AS post_id,
        COUNT(*) AS outgoing_links
    FROM postlinks pl
    GROUP BY pl.postid
    UNION ALL
    SELECT
        pl.relatedpostid AS post_id,
        COUNT(*) AS incoming_links
    FROM postlinks pl
    GROUP BY pl.relatedpostid
),

post_links_total AS (
    SELECT
        post_id,
        SUM(outgoing_links) AS total_links
    FROM post_links_agg
    GROUP BY post_id
)
SELECT
    tp.tag_id,
    COUNT(DISTINCT tp.post_id) AS post_count,
    AVG(tp.score) AS avg_score,
    SUM(tp.viewcount) AS total_views,
    AVG(tp.answercount) AS avg_answer_count,
    AVG(tp.owner_reputation) AS avg_owner_reputation,
    AVG(tp.editor_reputation) AS avg_editor_reputation,
    COUNT(DISTINCT tp.owneruserid) AS distinct_owner_users,
    COUNT(DISTINCT tp.lasteditoruserid) AS distinct_editor_users,
    COALESCE(SUM(pl.total_links), 0) AS total_related_links
FROM tag_posts tp
LEFT JOIN post_links_total pl ON tp.post_id = pl.post_id
GROUP BY tp.tag_id
ORDER BY total_related_links DESC
LIMIT 10
