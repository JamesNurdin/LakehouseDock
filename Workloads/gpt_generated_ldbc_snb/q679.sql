WITH tags AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM tag t
    LEFT JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
),
comment_metrics AS (
    SELECT
        ch.tag_id,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT c_child.id) AS reply_count,
        AVG(c.length) AS avg_comment_length
    FROM comment_has_tag_tag ch
    LEFT JOIN comment c
        ON ch.comment_id = c.id
    LEFT JOIN comment c_child
        ON c_child.parent_comment_id = c.id
    GROUP BY ch.tag_id
),
person_interest AS (
    SELECT
        pit.tag_id,
        COUNT(DISTINCT pit.person_id) AS person_interest_count
    FROM person_has_interest_tag pit
    GROUP BY pit.tag_id
),
forum_usage AS (
    SELECT
        fht.tag_id,
        COUNT(DISTINCT fht.forum_id) AS forum_count
    FROM forum_has_tag_tag fht
    GROUP BY fht.tag_id
),
post_usage AS (
    SELECT
        pht.tag_id,
        COUNT(DISTINCT pht.post_id) AS post_count
    FROM post_has_tag_tag pht
    GROUP BY pht.tag_id
)
SELECT
    t.tag_class_name,
    t.tag_name,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.reply_count, 0) AS reply_count,
    cm.avg_comment_length,
    COALESCE(pi.person_interest_count, 0) AS person_interest_count,
    COALESCE(fu.forum_count, 0) AS forum_count,
    COALESCE(pu.post_count, 0) AS post_count
FROM tags t
LEFT JOIN comment_metrics cm
    ON t.tag_id = cm.tag_id
LEFT JOIN person_interest pi
    ON t.tag_id = pi.tag_id
LEFT JOIN forum_usage fu
    ON t.tag_id = fu.tag_id
LEFT JOIN post_usage pu
    ON t.tag_id = pu.tag_id
ORDER BY comment_count DESC
LIMIT 100
