/*
  Analytical summary per tag class
  - Number of posts, average post length, distinct post creators
  - Number of forums, distinct moderators
  - Number of comments
  - Number of persons with an interest in the tag class
*/
WITH post_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count
    FROM tag_class tc
    JOIN tag t
        ON t.type_tag_class_id = tc.id
    JOIN post_has_tag_tag pht
        ON pht.tag_id = t.id
    JOIN post p
        ON p.id = pht.post_id
    GROUP BY tc.id
),
forum_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT f.id) AS forum_count,
        COUNT(DISTINCT f.moderator_person_id) AS distinct_moderator_count
    FROM tag_class tc
    JOIN tag t
        ON t.type_tag_class_id = tc.id
    JOIN forum_has_tag_tag fht
        ON fht.tag_id = t.id
    JOIN forum f
        ON f.id = fht.forum_id
    GROUP BY tc.id
),
comment_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT ch.comment_id) AS comment_count
    FROM tag_class tc
    JOIN tag t
        ON t.type_tag_class_id = tc.id
    JOIN comment_has_tag_tag ch
        ON ch.tag_id = t.id
    GROUP BY tc.id
),
person_interest_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT per.id) AS person_interest_count
    FROM tag_class tc
    JOIN tag t
        ON t.type_tag_class_id = tc.id
    JOIN person_has_interest_tag pit
        ON pit.tag_id = t.id
    JOIN person per
        ON per.id = pit.person_id
    GROUP BY tc.id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(pm.distinct_creator_count, 0) AS distinct_creator_count,
    COALESCE(fm.forum_count, 0) AS forum_count,
    COALESCE(fm.distinct_moderator_count, 0) AS distinct_moderator_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(pim.person_interest_count, 0) AS person_interest_count
FROM tag_class tc
LEFT JOIN post_metrics pm
    ON pm.tag_class_id = tc.id
LEFT JOIN forum_metrics fm
    ON fm.tag_class_id = tc.id
LEFT JOIN comment_metrics cm
    ON cm.tag_class_id = tc.id
LEFT JOIN person_interest_metrics pim
    ON pim.tag_class_id = tc.id
ORDER BY post_count DESC
LIMIT 10
