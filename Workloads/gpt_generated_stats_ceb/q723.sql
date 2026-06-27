WITH user_posts AS (
    SELECT
        p.id AS post_id,
        u.id AS user_id,
        u.reputation,
        p.score,
        p.viewcount,
        p.answercount
    FROM posts p
    JOIN users u ON p.owneruserid = u.id
),
outgoing_links AS (
    SELECT
        pl.postid AS post_id,
        COUNT(*) AS outgoing_cnt
    FROM postlinks pl
    GROUP BY pl.postid
),
incoming_links AS (
    SELECT
        pl.relatedpostid AS post_id,
        COUNT(*) AS incoming_cnt
    FROM postlinks pl
    GROUP BY pl.relatedpostid
),
tag_excerpts AS (
    SELECT
        t.excerptpostid AS post_id,
        COUNT(*) AS tag_cnt
    FROM tags t
    GROUP BY t.excerptpostid
)
SELECT
    up.user_id,
    up.reputation,
    COUNT(up.post_id) AS total_posts_owned,
    COALESCE(SUM(up.score), 0) AS total_score_owned,
    COALESCE(SUM(up.viewcount), 0) AS total_viewcount_owned,
    COALESCE(AVG(up.answercount), 0) AS avg_answercount_owned,
    COALESCE(SUM(COALESCE(ol.outgoing_cnt, 0)), 0) AS total_links_from_owned,
    COALESCE(SUM(COALESCE(il.incoming_cnt, 0)), 0) AS total_links_to_owned,
    COALESCE(SUM(COALESCE(te.tag_cnt, 0)), 0) AS total_tags_excerpts_owned
FROM user_posts up
LEFT JOIN outgoing_links ol ON ol.post_id = up.post_id
LEFT JOIN incoming_links il ON il.post_id = up.post_id
LEFT JOIN tag_excerpts te ON te.post_id = up.post_id
GROUP BY up.user_id, up.reputation
ORDER BY total_score_owned DESC
LIMIT 10
