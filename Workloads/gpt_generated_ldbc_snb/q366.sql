WITH forum_members AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_tags AS (
    SELECT f.id AS forum_id,
           t.id AS tag_id,
           tc.id AS tag_class_id,
           tc.name AS tag_class_name
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    JOIN tag t ON t.id = pht.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id

    UNION ALL

    SELECT f.id AS forum_id,
           t.id AS tag_id,
           tc.id AS tag_class_id,
           tc.name AS tag_class_name
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON t.id = cht.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id
),
forum_tag_stats AS (
    SELECT forum_id,
           COUNT(DISTINCT tag_id) AS distinct_tag_count
    FROM forum_tags
    GROUP BY forum_id
),
forum_tag_class_usage AS (
    SELECT forum_id,
           tag_class_name,
           COUNT(*) AS usage_count
    FROM forum_tags
    GROUP BY forum_id, tag_class_name
),
forum_tag_class_rank AS (
    SELECT forum_id,
           tag_class_name,
           usage_count,
           ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY usage_count DESC) AS rn
    FROM forum_tag_class_usage
),
forum_top_tag_class AS (
    SELECT forum_id,
           tag_class_name AS top_tag_class_name,
           usage_count AS top_tag_class_usage
    FROM forum_tag_class_rank
    WHERE rn = 1
),
forum_moderator AS (
    SELECT f.id AS forum_id,
           p.first_name,
           p.last_name
    FROM forum f
    JOIN person p ON p.id = f.moderator_person_id
)
SELECT f.id AS forum_id,
       f.title AS forum_title,
       CONCAT(m.first_name, ' ', m.last_name) AS moderator_name,
       COALESCE(mb.member_count, 0) AS member_count,
       COALESCE(fp.post_count, 0) AS post_count,
       COALESCE(fp.avg_post_length, 0) AS avg_post_length,
       COALESCE(fc.comment_count, 0) AS comment_count,
       COALESCE(ts.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(ttc.top_tag_class_name, 'N/A') AS top_tag_class_name,
       COALESCE(ttc.top_tag_class_usage, 0) AS top_tag_class_usage
FROM forum f
LEFT JOIN forum_moderator m ON m.forum_id = f.id
LEFT JOIN forum_members mb ON mb.forum_id = f.id
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_tag_stats ts ON ts.forum_id = f.id
LEFT JOIN forum_top_tag_class ttc ON ttc.forum_id = f.id
ORDER BY f.id
