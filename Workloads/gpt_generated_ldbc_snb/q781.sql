WITH
    -- Posts together with their tag class and the forum they belong to
    post_tag AS (
        SELECT DISTINCT
            p.id AS post_id,
            p.container_forum_id AS forum_id,
            p.length AS post_length,
            tc.id AS tag_class_id,
            tc.name AS tag_class_name
        FROM post p
        JOIN post_has_tag_tag pht ON pht.post_id = p.id
        JOIN tag t ON t.id = pht.tag_id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
    ),
    -- Aggregate post statistics per forum / tag class
    post_agg AS (
        SELECT
            pt.forum_id,
            pt.tag_class_id,
            pt.tag_class_name,
            COUNT(pt.post_id) AS post_count,
            AVG(pt.post_length) AS avg_post_length
        FROM post_tag pt
        GROUP BY pt.forum_id, pt.tag_class_id, pt.tag_class_name
    ),
    -- Comments together with their tag class and the forum they belong to (via parent post)
    comment_tag AS (
        SELECT DISTINCT
            c.id AS comment_id,
            p.container_forum_id AS forum_id,
            c.length AS comment_length,
            tc.id AS tag_class_id,
            tc.name AS tag_class_name
        FROM comment c
        JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
        JOIN tag t ON t.id = cht.tag_id
        JOIN tag_class tc ON t.type_tag_class_id = tc.id
        JOIN post p ON c.parent_post_id = p.id
    ),
    -- Aggregate comment statistics per forum / tag class
    comment_agg AS (
        SELECT
            ct.forum_id,
            ct.tag_class_id,
            ct.tag_class_name,
            COUNT(ct.comment_id) AS comment_count,
            AVG(ct.comment_length) AS avg_comment_length
        FROM comment_tag ct
        GROUP BY ct.forum_id, ct.tag_class_id, ct.tag_class_name
    ),
    -- Basic forum information
    forum_info AS (
        SELECT
            f.id AS forum_id,
            f.title AS forum_title
        FROM forum f
    ),
    -- All forum‑tag‑class combinations that appear in either posts or comments
    forum_tag_class AS (
        SELECT forum_id, tag_class_id, tag_class_name FROM post_agg
        UNION
        SELECT forum_id, tag_class_id, tag_class_name FROM comment_agg
    )
SELECT
    fi.forum_id,
    fi.forum_title,
    ftc.tag_class_name,
    COALESCE(pa.post_count, 0) AS post_count,
    COALESCE(ca.comment_count, 0) AS comment_count,
    pa.avg_post_length,
    ca.avg_comment_length
FROM forum_info fi
JOIN forum_tag_class ftc ON ftc.forum_id = fi.forum_id
LEFT JOIN post_agg pa ON pa.forum_id = ftc.forum_id AND pa.tag_class_id = ftc.tag_class_id
LEFT JOIN comment_agg ca ON ca.forum_id = ftc.forum_id AND ca.tag_class_id = ftc.tag_class_id
ORDER BY fi.forum_id, ftc.tag_class_name
