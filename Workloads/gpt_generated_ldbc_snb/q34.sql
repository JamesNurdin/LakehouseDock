/*
   Analytical query: For each forum, compute the total number of members, the moderator’s name,
   and comment statistics (count, average length, earliest and latest comment dates) generated
   by the forum’s members.
*/
WITH member_counts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT fm.person_id) AS member_count,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person mod
        ON mod.id = f.moderator_person_id
    GROUP BY
        f.id,
        f.title,
        mod.first_name,
        mod.last_name
),
comment_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        MIN(c.creation_date) AS earliest_comment_date,
        MAX(c.creation_date) AS latest_comment_date
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person p
        ON p.id = fm.person_id
    JOIN comment c
        ON c.creator_person_id = p.id
    GROUP BY f.id
)
SELECT
    mc.forum_id,
    mc.forum_title,
    mc.member_count,
    cs.comment_count,
    cs.avg_comment_length,
    cs.earliest_comment_date,
    cs.latest_comment_date,
    mc.moderator_first_name,
    mc.moderator_last_name
FROM member_counts mc
LEFT JOIN comment_stats cs
    ON cs.forum_id = mc.forum_id
ORDER BY cs.comment_count DESC NULLS LAST
LIMIT 10
