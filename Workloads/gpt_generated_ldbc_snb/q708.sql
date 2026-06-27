-- For each forum: moderator name, total members, total tags, and number of members who are interested in at least one forum tag
WITH forum_members AS (
    SELECT
        f.id AS forum_id,
        f.title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN person mod
        ON f.moderator_person_id = mod.id
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id, f.title, mod.first_name, mod.last_name
),
forum_tags AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum f
    JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    GROUP BY f.id
),
forum_member_tag_interest AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_interest_tag_count
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person_has_interest_tag pit
        ON pit.person_id = fm.person_id
    JOIN tag t
        ON t.id = pit.tag_id
    JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
        AND ft.tag_id = t.id
    GROUP BY f.id
)
SELECT
    fm.forum_id,
    fm.title,
    fm.moderator_first_name,
    fm.moderator_last_name,
    fm.member_count,
    ft.tag_count,
    fmi.member_interest_tag_count
FROM forum_members fm
LEFT JOIN forum_tags ft
    ON ft.forum_id = fm.forum_id
LEFT JOIN forum_member_tag_interest fmi
    ON fmi.forum_id = fm.forum_id
ORDER BY fm.member_count DESC
LIMIT 100
