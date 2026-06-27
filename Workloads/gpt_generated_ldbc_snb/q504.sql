/*
  Analytical query: number of distinct forums that have tags belonging to each parent tag class.
  It joins the forum, forum_has_tag_tag, tag, and tag_class tables following the allowed join rules.
*/
WITH forum_tag_hierarchy AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        t.id AS tag_id,
        t.name AS tag_name,
        c.id AS child_tag_class_id,
        c.name AS child_tag_class_name,
        p.id AS parent_tag_class_id,
        p.name AS parent_tag_class_name
    FROM forum_has_tag_tag fht
    JOIN forum f
        ON fht.forum_id = f.id
    JOIN tag t
        ON fht.tag_id = t.id
    JOIN tag_class c
        ON t.type_tag_class_id = c.id
    LEFT JOIN tag_class p
        ON c.subclass_of_tag_class_id = p.id
)
SELECT
    ft.parent_tag_class_id,
    ft.parent_tag_class_name,
    COUNT(DISTINCT ft.forum_id) AS distinct_forum_count,
    COUNT(*) AS tag_assignments
FROM forum_tag_hierarchy ft
WHERE ft.parent_tag_class_id IS NOT NULL
GROUP BY ft.parent_tag_class_id, ft.parent_tag_class_name
ORDER BY distinct_forum_count DESC
LIMIT 20
