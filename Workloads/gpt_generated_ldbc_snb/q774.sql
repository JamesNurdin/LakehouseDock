WITH post_metrics AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           COUNT(p.id) AS total_posts,
           AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
comment_metrics AS (
    SELECT f.id AS forum_id,
           COUNT(c.id) AS total_comments,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    GROUP BY f.id
),
tag_usage AS (
    SELECT f.id AS forum_id,
           t.id AS tag_id,
           tc.id AS tag_class_id,
           tc.name AS tag_class_name
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    JOIN tag t ON pt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id

    UNION ALL

    SELECT f.id AS forum_id,
           t.id AS tag_id,
           tc.id AS tag_class_id,
           tc.name AS tag_class_name
    FROM comment_has_tag_tag ct
    JOIN comment c ON ct.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    JOIN tag t ON ct.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
distinct_tag_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT tag_id) AS distinct_tags
    FROM tag_usage
    GROUP BY forum_id
),
tag_class_counts AS (
    SELECT forum_id,
           tag_class_name,
           COUNT(*) AS usage_count
    FROM tag_usage
    GROUP BY forum_id, tag_class_name
),
top_tag_class_per_forum AS (
    SELECT forum_id,
           tag_class_name AS top_tag_class,
           usage_count
    FROM (
        SELECT forum_id,
               tag_class_name,
               usage_count,
               ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY usage_count DESC) AS rn
        FROM tag_class_counts
    ) t
    WHERE rn = 1
),
moderator_info AS (
    SELECT f.id AS forum_id,
           p.first_name,
           p.last_name
    FROM forum f
    JOIN person p ON f.moderator_person_id = p.id
),
forum_list AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title
    FROM forum f
)
SELECT fl.forum_id,
       fl.forum_title,
       mi.first_name || ' ' || mi.last_name AS moderator_name,
       pm.total_posts,
       cm.total_comments,
       pm.avg_post_length,
       cm.avg_comment_length,
       dtc.distinct_tags,
       tt.top_tag_class
FROM forum_list fl
LEFT JOIN moderator_info mi ON mi.forum_id = fl.forum_id
LEFT JOIN post_metrics pm ON pm.forum_id = fl.forum_id
LEFT JOIN comment_metrics cm ON cm.forum_id = fl.forum_id
LEFT JOIN distinct_tag_counts dtc ON dtc.forum_id = fl.forum_id
LEFT JOIN top_tag_class_per_forum tt ON tt.forum_id = fl.forum_id
ORDER BY pm.total_posts DESC NULLS LAST
LIMIT 100
