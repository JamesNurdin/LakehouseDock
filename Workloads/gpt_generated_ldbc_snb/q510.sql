-- Count distinct entities (comments, posts, forums, persons) that use tags belonging to each parent tag class
WITH tag_usage AS (
    SELECT t.id AS tag_id,
           t.type_tag_class_id AS tag_class_id,
           'comment' AS usage_type,
           ch.comment_id AS entity_id
    FROM comment_has_tag_tag ch
    JOIN tag t ON ch.tag_id = t.id
    UNION ALL
    SELECT t.id,
           t.type_tag_class_id,
           'post',
           ph.post_id
    FROM post_has_tag_tag ph
    JOIN tag t ON ph.tag_id = t.id
    UNION ALL
    SELECT t.id,
           t.type_tag_class_id,
           'forum',
           fh.forum_id
    FROM forum_has_tag_tag fh
    JOIN tag t ON fh.tag_id = t.id
    UNION ALL
    SELECT t.id,
           t.type_tag_class_id,
           'person',
           pht.person_id
    FROM person_has_interest_tag pht
    JOIN tag t ON pht.tag_id = t.id
)
SELECT parent_tc.id AS parent_tag_class_id,
       parent_tc.name AS parent_tag_class_name,
       COUNT(DISTINCT tu.tag_id) AS distinct_tag_count,
       COUNT(DISTINCT CASE WHEN tu.usage_type = 'comment' THEN tu.entity_id END) AS comment_entity_count,
       COUNT(DISTINCT CASE WHEN tu.usage_type = 'post' THEN tu.entity_id END) AS post_entity_count,
       COUNT(DISTINCT CASE WHEN tu.usage_type = 'forum' THEN tu.entity_id END) AS forum_entity_count,
       COUNT(DISTINCT CASE WHEN tu.usage_type = 'person' THEN tu.entity_id END) AS person_entity_count
FROM tag_usage tu
JOIN tag_class child_tc ON tu.tag_class_id = child_tc.id
JOIN tag_class parent_tc ON child_tc.subclass_of_tag_class_id = parent_tc.id
GROUP BY parent_tc.id, parent_tc.name
ORDER BY comment_entity_count DESC, post_entity_count DESC
