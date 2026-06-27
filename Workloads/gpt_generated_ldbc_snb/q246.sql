WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_post_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(pl.person_id) AS post_like_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY f.id
),
forum_comment_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(cl.person_id) AS comment_like_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY f.id
),
forum_members AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT pt.tag_id) AS distinct_tag_count,
        COUNT(DISTINCT plc.id) AS distinct_city_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN person p
        ON p.id = fm.person_id
    LEFT JOIN person_has_interest_tag pt
        ON pt.person_id = p.id
    LEFT JOIN place plc
        ON plc.id = p.location_city_id
    GROUP BY f.id
),
forum_moderator AS (
    SELECT
        f.id AS forum_id,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person p
        ON p.id = f.moderator_person_id
)
SELECT
    fp.forum_id,
    fp.forum_title,
    fp.post_count,
    fp.avg_post_length,
    fc.comment_count,
    fc.avg_comment_length,
    fpl.post_like_count,
    fcl.comment_like_count,
    fm.member_count,
    fm.distinct_tag_count,
    fm.distinct_city_count,
    fmtr.moderator_first_name,
    fmtr.moderator_last_name
FROM forum_posts fp
LEFT JOIN forum_comments fc
    ON fc.forum_id = fp.forum_id
LEFT JOIN forum_post_likes fpl
    ON fpl.forum_id = fp.forum_id
LEFT JOIN forum_comment_likes fcl
    ON fcl.forum_id = fp.forum_id
LEFT JOIN forum_members fm
    ON fm.forum_id = fp.forum_id
LEFT JOIN forum_moderator fmtr
    ON fmtr.forum_id = fp.forum_id
ORDER BY fp.post_count DESC
LIMIT 100
