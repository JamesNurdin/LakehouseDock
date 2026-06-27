WITH tag_interest AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        p.id AS person_id
    FROM tag t
    JOIN person_has_interest_tag pit
        ON pit.tag_id = t.id
    JOIN person p
        ON p.id = pit.person_id
),
person_comment_stats AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT c.id) AS comment_cnt,
        COALESCE(SUM(c.length), 0) AS total_length,
        CASE WHEN COUNT(DISTINCT c.id) > 0
             THEN CAST(COALESCE(SUM(c.length), 0) AS double) / COUNT(DISTINCT c.id)
             ELSE 0
        END AS avg_length,
        COUNT(DISTINCT plc.comment_id) AS liked_comments_cnt
    FROM person p
    LEFT JOIN comment c
        ON c.creator_person_id = p.id
    LEFT JOIN person_likes_comment plc
        ON plc.person_id = p.id
    GROUP BY p.id
),
tag_aggregates AS (
    SELECT
        ti.tag_id,
        ti.tag_name,
        COUNT(DISTINCT ti.person_id) AS interested_person_cnt,
        COALESCE(SUM(pcs.comment_cnt), 0) AS total_comments_by_interested,
        COALESCE(SUM(pcs.total_length), 0) AS total_comment_length_by_interested,
        CASE WHEN COALESCE(SUM(pcs.comment_cnt), 0) > 0
             THEN CAST(COALESCE(SUM(pcs.total_length), 0) AS double) / COALESCE(SUM(pcs.comment_cnt), 0)
             ELSE 0
        END AS avg_comment_length_by_interested,
        COALESCE(SUM(pcs.liked_comments_cnt), 0) AS total_likes_on_comments_by_interested
    FROM tag_interest ti
    LEFT JOIN person_comment_stats pcs
        ON pcs.person_id = ti.person_id
    GROUP BY ti.tag_id, ti.tag_name
)
SELECT
    tag_id,
    tag_name,
    interested_person_cnt,
    total_comments_by_interested,
    total_comment_length_by_interested,
    avg_comment_length_by_interested,
    total_likes_on_comments_by_interested
FROM tag_aggregates
ORDER BY total_comments_by_interested DESC
LIMIT 20
