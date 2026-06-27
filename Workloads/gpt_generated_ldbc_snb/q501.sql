WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        f.moderator_person_id,
        COUNT(DISTINCT fm.person_id) AS member_count,
        MIN(fm.creation_date) AS earliest_member_join_date,
        MAX(fm.creation_date) AS latest_member_join_date
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id, f.title, f.creation_date, f.moderator_person_id
),
moderator_stats AS (
    SELECT
        fs.moderator_person_id,
        COUNT(*) AS forums_moderated,
        SUM(fs.member_count) AS total_members,
        AVG(fs.member_count) AS avg_members_per_forum
    FROM forum_stats fs
    GROUP BY fs.moderator_person_id
)
SELECT
    ms.moderator_person_id,
    ms.forums_moderated,
    ms.total_members,
    ms.avg_members_per_forum,
    MAX(fs.member_count) AS max_members_in_forum,
    MIN(fs.member_count) AS min_members_in_forum
FROM moderator_stats ms
JOIN forum_stats fs
    ON fs.moderator_person_id = ms.moderator_person_id
GROUP BY
    ms.moderator_person_id,
    ms.forums_moderated,
    ms.total_members,
    ms.avg_members_per_forum
ORDER BY ms.total_members DESC
LIMIT 10
