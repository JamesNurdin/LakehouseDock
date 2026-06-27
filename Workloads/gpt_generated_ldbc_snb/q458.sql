WITH parent_comments AS (
    SELECT 
        c.id AS parent_id,
        c.creator_person_id,
        c.length,
        ct.tag_id
    FROM comment c
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    WHERE c.parent_comment_id IS NULL
),
tagged_parents AS (
    SELECT 
        p.parent_id,
        p.creator_person_id,
        p.length,
        p.tag_id,
        t.name AS tag_name
    FROM parent_comments p
    JOIN tag t ON p.tag_id = t.id
),
reply_counts AS (
    SELECT 
        tp.tag_id,
        COUNT(r.id) AS reply_count
    FROM tagged_parents tp
    JOIN comment r ON r.parent_comment_id = tp.parent_id
    GROUP BY tp.tag_id
),
parent_agg AS (
    SELECT 
        tp.tag_id,
        COUNT(tp.parent_id) AS top_level_comments,
        AVG(tp.length) AS avg_length,
        COUNT(DISTINCT tp.creator_person_id) AS distinct_creators
    FROM tagged_parents tp
    GROUP BY tp.tag_id
)
SELECT 
    t.id AS tag_id,
    t.name AS tag_name,
    pa.top_level_comments,
    pa.avg_length,
    pa.distinct_creators,
    COALESCE(rc.reply_count, 0) AS total_replies
FROM parent_agg pa
JOIN tag t ON pa.tag_id = t.id
LEFT JOIN reply_counts rc ON pa.tag_id = rc.tag_id
ORDER BY pa.top_level_comments DESC
LIMIT 10
