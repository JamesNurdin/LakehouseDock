WITH post_counts AS (
    SELECT tag_id,
           COUNT(DISTINCT post_id) AS post_cnt
    FROM post_has_tag_tag
    GROUP BY tag_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    f.moderator_person_id AS moderator_id,
    t.id AS tag_id,
    t.name AS tag_name,
    COALESCE(pc.post_cnt, 0) AS post_count_for_tag
FROM forum f
JOIN forum_has_tag_tag fht
    ON f.id = fht.forum_id
JOIN tag t
    ON fht.tag_id = t.id
LEFT JOIN post_counts pc
    ON t.id = pc.tag_id
ORDER BY post_count_for_tag DESC
LIMIT 100
