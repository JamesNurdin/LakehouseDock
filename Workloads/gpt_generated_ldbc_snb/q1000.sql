WITH forum_metrics AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id, f.title
),
post_metrics AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           COUNT(DISTINCT pl.person_id) AS post_like_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY f.id
),
comment_metrics AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length,
           COUNT(DISTINCT cl.person_id) AS comment_like_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY f.id
),
all_forum_tags AS (
    SELECT f.id AS forum_id,
           t.id AS tag_id,
           tc.id AS tag_class_id,
           tc.name AS tag_class_name
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    LEFT JOIN tag t
        ON t.id = pt.tag_id
    LEFT JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
    UNION ALL
    SELECT f.id AS forum_id,
           t.id AS tag_id,
           tc.id AS tag_class_id,
           tc.name AS tag_class_name
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN comment_has_tag_tag ct
        ON ct.comment_id = c.id
    LEFT JOIN tag t
        ON t.id = ct.tag_id
    LEFT JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
),
tag_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT tag_id) AS distinct_tag_count
    FROM all_forum_tags
    GROUP BY forum_id
),
tag_class_counts AS (
    SELECT forum_id,
           tag_class_name,
           COUNT(*) AS tag_class_tag_count
    FROM all_forum_tags
    WHERE tag_id IS NOT NULL
    GROUP BY forum_id, tag_class_name
),
top_tag_class AS (
    SELECT forum_id,
           tag_class_name,
           tag_class_tag_count
    FROM (
        SELECT forum_id,
               tag_class_name,
               tag_class_tag_count,
               ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_class_tag_count DESC) AS rn
        FROM tag_class_counts
    )
    WHERE rn = 1
)
SELECT fm.forum_id,
       fm.forum_title,
       fm.member_count,
       pm.post_count,
       pm.post_like_count,
       cm.comment_count,
       cm.avg_comment_length,
       cm.comment_like_count,
       tc.distinct_tag_count,
       ttc.tag_class_name AS top_tag_class,
       ttc.tag_class_tag_count AS top_tag_class_tag_count
FROM forum_metrics fm
LEFT JOIN post_metrics pm
    ON pm.forum_id = fm.forum_id
LEFT JOIN comment_metrics cm
    ON cm.forum_id = fm.forum_id
LEFT JOIN tag_counts tc
    ON tc.forum_id = fm.forum_id
LEFT JOIN top_tag_class ttc
    ON ttc.forum_id = fm.forum_id
ORDER BY fm.member_count DESC
LIMIT 100
