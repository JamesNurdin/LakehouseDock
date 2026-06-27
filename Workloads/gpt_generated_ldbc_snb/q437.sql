WITH forum_total_tags AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fht.tag_id) AS total_tags,
        COUNT(DISTINCT tc.id) AS distinct_tag_classes
    FROM forum f
    JOIN forum_has_tag_tag fht ON f.id = fht.forum_id
    JOIN tag t ON fht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY f.id
),
moderator_matching_interests AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT pit.tag_id) AS matching_interests
    FROM forum f
    JOIN person p ON f.moderator_person_id = p.id
    JOIN person_has_interest_tag pit ON p.id = pit.person_id
    JOIN tag t_i ON pit.tag_id = t_i.id
    JOIN forum_has_tag_tag fht ON f.id = fht.forum_id AND fht.tag_id = t_i.id
    GROUP BY f.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    CONCAT(p.first_name, ' ', p.last_name) AS moderator_name,
    ft.total_tags,
    ft.distinct_tag_classes,
    COALESCE(mi.matching_interests, 0) AS matching_interests
FROM forum f
JOIN person p ON f.moderator_person_id = p.id
LEFT JOIN forum_total_tags ft ON f.id = ft.forum_id
LEFT JOIN moderator_matching_interests mi ON f.id = mi.forum_id
ORDER BY ft.total_tags DESC, f.id
