WITH member_counts AS (
    SELECT
        forum_id,
        count(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        count(DISTINCT p.id) AS post_count,
        avg(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
forum_tags AS (
    SELECT
        fht.forum_id,
        count(DISTINCT fht.tag_id) AS tag_count,
        count(DISTINCT tc.id) AS tag_class_count
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY fht.forum_id
),
overlap_members AS (
    SELECT
        f.id AS forum_id,
        count(DISTINCT p.id) AS overlap_member_count
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    JOIN person p ON fm.person_id = p.id
    JOIN forum_has_tag_tag ft ON ft.forum_id = f.id
    JOIN tag t ON ft.tag_id = t.id
    JOIN person_has_interest_tag pit ON pit.person_id = p.id AND pit.tag_id = t.id
    GROUP BY f.id
)
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    mc.member_count,
    ps.post_count,
    ps.avg_post_length,
    ft.tag_count,
    ft.tag_class_count,
    om.overlap_member_count
FROM forum f
LEFT JOIN person mod ON f.moderator_person_id = mod.id
LEFT JOIN member_counts mc ON f.id = mc.forum_id
LEFT JOIN post_stats ps ON f.id = ps.forum_id
LEFT JOIN forum_tags ft ON f.id = ft.forum_id
LEFT JOIN overlap_members om ON f.id = om.forum_id
ORDER BY f.id
