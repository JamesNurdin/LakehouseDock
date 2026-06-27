WITH post_tag_links AS (
    SELECT DISTINCT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        p.id AS post_id,
        p.length AS post_length,
        p.creator_person_id AS creator_id
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
),
post_tag_metrics AS (
    SELECT
        tag_class_id,
        tag_class_name,
        COUNT(DISTINCT post_id) AS post_count,
        AVG(post_length) AS avg_post_length,
        COUNT(DISTINCT creator_id) AS distinct_creator_count
    FROM post_tag_links
    GROUP BY tag_class_id, tag_class_name
),
forum_tag_links AS (
    SELECT DISTINCT
        tc.id AS tag_class_id,
        f.id AS forum_id,
        f.moderator_person_id AS moderator_id
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN forum_has_tag_tag fht ON fht.tag_id = t.id
    JOIN forum f ON f.id = fht.forum_id
),
forum_tag_metrics AS (
    SELECT
        tag_class_id,
        COUNT(DISTINCT forum_id) AS forum_count,
        COUNT(DISTINCT moderator_id) AS distinct_moderator_count
    FROM forum_tag_links
    GROUP BY tag_class_id
),
person_interest_links AS (
    SELECT DISTINCT
        tc.id AS tag_class_id,
        ph.person_id AS person_id
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN person_has_interest_tag ph ON ph.tag_id = t.id
),
person_interest_metrics AS (
    SELECT
        tag_class_id,
        COUNT(DISTINCT person_id) AS interest_person_count
    FROM person_interest_links
    GROUP BY tag_class_id
)
SELECT
    ptm.tag_class_id,
    ptm.tag_class_name,
    ptm.post_count,
    ptm.avg_post_length,
    ptm.distinct_creator_count,
    ftm.forum_count,
    ftm.distinct_moderator_count,
    pim.interest_person_count
FROM post_tag_metrics ptm
LEFT JOIN forum_tag_metrics ftm ON ftm.tag_class_id = ptm.tag_class_id
LEFT JOIN person_interest_metrics pim ON pim.tag_class_id = ptm.tag_class_id
ORDER BY ptm.post_count DESC
LIMIT 50
