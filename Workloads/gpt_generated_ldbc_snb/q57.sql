WITH forum_members AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.moderator_person_id,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person p
        ON f.moderator_person_id = p.id
    GROUP BY f.id, f.title, f.moderator_person_id, p.first_name, p.last_name
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        SUM(c.length) AS total_comment_length
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person mem
        ON fm.person_id = mem.id
    JOIN comment c
        ON c.creator_person_id = mem.id
    GROUP BY f.id
)
SELECT
    fm.forum_id,
    fm.title,
    fm.member_count,
    fc.comment_count,
    fc.avg_comment_length,
    (fc.comment_count * 1.0) / nullif(fm.member_count, 0) AS comments_per_member,
    fm.moderator_first_name,
    fm.moderator_last_name
FROM forum_members fm
LEFT JOIN forum_comments fc
    ON fm.forum_id = fc.forum_id
ORDER BY fc.comment_count DESC NULLS LAST
LIMIT 10
