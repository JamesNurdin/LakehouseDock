WITH post_tag_class AS (
    SELECT
        p.id AS post_id,
        p.creator_person_id AS creator_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM post_has_tag_tag ptt
    JOIN post p ON ptt.post_id = p.id
    JOIN tag t ON ptt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
forum_tag_class AS (
    SELECT
        f.id AS forum_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM forum_has_tag_tag ftt
    JOIN forum f ON ftt.forum_id = f.id
    JOIN tag t ON ftt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
forum_members_by_class AS (
    SELECT
        fmp.person_id AS member_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM forum_has_member_person fmp
    JOIN forum f ON fmp.forum_id = f.id
    JOIN forum_has_tag_tag ftt ON ftt.forum_id = f.id
    JOIN tag t ON ftt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
person_interests_by_class AS (
    SELECT
        p.id AS person_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM person_has_interest_tag pit
    JOIN person p ON pit.person_id = p.id
    JOIN tag t ON pit.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COUNT(DISTINCT ptc.post_id) AS total_posts,
    COUNT(DISTINCT ptc.creator_id) AS distinct_creators,
    COUNT(DISTINCT ftc.forum_id) AS total_forums,
    COUNT(DISTINCT fmb.member_id) AS distinct_forum_members,
    COUNT(DISTINCT pi.person_id) AS distinct_interested_persons
FROM tag_class tc
LEFT JOIN post_tag_class ptc ON ptc.tag_class_id = tc.id
LEFT JOIN forum_tag_class ftc ON ftc.tag_class_id = tc.id
LEFT JOIN forum_members_by_class fmb ON fmb.tag_class_id = tc.id
LEFT JOIN person_interests_by_class pi ON pi.tag_class_id = tc.id
GROUP BY
    tc.id,
    tc.name
ORDER BY
    total_posts DESC
LIMIT 10
