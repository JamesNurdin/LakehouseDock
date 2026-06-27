WITH post_agg AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p_mod.first_name AS mod_first_name,
        p_mod.last_name AS mod_last_name,
        COUNT(po.id) AS post_count,
        AVG(po.length) AS avg_post_length
    FROM post po
    JOIN forum f
        ON po.container_forum_id = f.id
    JOIN person p_mod
        ON f.moderator_person_id = p_mod.id
    GROUP BY f.id, f.title, p_mod.first_name, p_mod.last_name
),
comment_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS unique_commenters
    FROM comment c
    JOIN post po
        ON c.parent_post_id = po.id
    JOIN forum f
        ON po.container_forum_id = f.id
    WHERE c.parent_post_id IS NOT NULL
    GROUP BY f.id
)
SELECT
    pa.forum_id,
    pa.forum_title,
    pa.mod_first_name,
    pa.mod_last_name,
    pa.post_count,
    ca.comment_count,
    CAST(ca.comment_count AS double) / NULLIF(pa.post_count, 0) AS comment_to_post_ratio,
    pa.avg_post_length,
    ca.avg_comment_length,
    ca.unique_commenters
FROM post_agg pa
JOIN comment_agg ca
    ON pa.forum_id = ca.forum_id
ORDER BY comment_to_post_ratio DESC
LIMIT 10
