WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title,
           f.creation_date,
           f.moderator_person_id,
           mod.first_name AS moderator_first_name,
           mod.last_name AS moderator_last_name
    FROM forum AS f
    LEFT JOIN person AS mod ON f.moderator_person_id = mod.id
),

member_counts AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),

post_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),

comment_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),

tag_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT tag_id) AS distinct_tag_count
    FROM (
        -- Tags directly attached to forums
        SELECT fht.forum_id AS forum_id,
               fht.tag_id AS tag_id
        FROM forum_has_tag_tag fht
        UNION ALL
        -- Tags attached to posts within forums
        SELECT p.container_forum_id AS forum_id,
               pht.tag_id AS tag_id
        FROM post_has_tag_tag pht
        JOIN post p ON pht.post_id = p.id
        UNION ALL
        -- Tags attached to comments (via the post's forum)
        SELECT p.container_forum_id AS forum_id,
               cht.tag_id AS tag_id
        FROM comment_has_tag_tag cht
        JOIN comment c ON cht.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
    ) AS all_tags
    GROUP BY forum_id
),

tag_class_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT tc.id) AS distinct_tag_class_count
    FROM (
        -- Tag classes from forum tags
        SELECT fht.forum_id AS forum_id,
               t.type_tag_class_id AS tag_class_id
        FROM forum_has_tag_tag fht
        JOIN tag t ON fht.tag_id = t.id
        UNION ALL
        -- Tag classes from post tags
        SELECT p.container_forum_id AS forum_id,
               t.type_tag_class_id AS tag_class_id
        FROM post_has_tag_tag pht
        JOIN post p ON pht.post_id = p.id
        JOIN tag t ON pht.tag_id = t.id
        UNION ALL
        -- Tag classes from comment tags
        SELECT p.container_forum_id AS forum_id,
               t.type_tag_class_id AS tag_class_id
        FROM comment_has_tag_tag cht
        JOIN comment c ON cht.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        JOIN tag t ON cht.tag_id = t.id
    ) AS all_tag_classes
    JOIN tag_class tc ON all_tag_classes.tag_class_id = tc.id
    GROUP BY forum_id
)

SELECT fb.forum_id,
       fb.title,
       fb.moderator_first_name,
       fb.moderator_last_name,
       COALESCE(mc.member_count, 0) AS member_count,
       COALESCE(pm.post_count, 0) AS post_count,
       COALESCE(pm.avg_post_length, 0) AS avg_post_length,
       COALESCE(cm.comment_count, 0) AS comment_count,
       COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(tc.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(tcc.distinct_tag_class_count, 0) AS distinct_tag_class_count
FROM forum_base fb
LEFT JOIN member_counts mc ON fb.forum_id = mc.forum_id
LEFT JOIN post_metrics pm ON fb.forum_id = pm.forum_id
LEFT JOIN comment_metrics cm ON fb.forum_id = cm.forum_id
LEFT JOIN tag_counts tc ON fb.forum_id = tc.forum_id
LEFT JOIN tag_class_counts tcc ON fb.forum_id = tcc.forum_id
ORDER BY fb.forum_id
