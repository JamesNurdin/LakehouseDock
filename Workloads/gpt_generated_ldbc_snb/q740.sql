WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title
    FROM forum f
),
forum_member_counts AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fhmp.person_id) AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fhmp
        ON fhmp.forum_id = f.id
    GROUP BY f.id
),
forum_post_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(pst.id) AS post_count,
        AVG(pst.length) AS avg_post_length,
        COUNT(DISTINCT pst.creator_person_id) AS distinct_creator_count
    FROM forum f
    LEFT JOIN post pst
        ON pst.container_forum_id = f.id
    GROUP BY f.id
),
forum_moderators AS (
    SELECT
        f.id AS forum_id,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name,
        p.gender AS moderator_gender
    FROM forum f
    LEFT JOIN person p
        ON f.moderator_person_id = p.id
),
forum_gender_post_stats AS (
    SELECT
        f.id AS forum_id,
        per.gender AS creator_gender,
        COUNT(pst.id) AS gender_post_count,
        AVG(pst.length) AS gender_avg_length
    FROM forum f
    LEFT JOIN post pst
        ON pst.container_forum_id = f.id
    LEFT JOIN person per
        ON pst.creator_person_id = per.id
    GROUP BY f.id, per.gender
)
SELECT
    fb.forum_id,
    fb.forum_title,
    fmc.member_count,
    fps.post_count,
    fps.avg_post_length,
    fps.distinct_creator_count,
    fm.moderator_first_name,
    fm.moderator_last_name,
    fm.moderator_gender,
    fgps.creator_gender,
    fgps.gender_post_count,
    fgps.gender_avg_length
FROM forum_base fb
LEFT JOIN forum_member_counts fmc
    ON fb.forum_id = fmc.forum_id
LEFT JOIN forum_post_stats fps
    ON fb.forum_id = fps.forum_id
LEFT JOIN forum_moderators fm
    ON fb.forum_id = fm.forum_id
LEFT JOIN forum_gender_post_stats fgps
    ON fb.forum_id = fgps.forum_id
ORDER BY fps.post_count DESC
LIMIT 10
