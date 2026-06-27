WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        COUNT(p.id) AS post_count
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_post_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(plp.person_id) AS post_like_count
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY f.id
),
forum_comment_likes AS (
    SELECT
        f.id AS forum_id,
        COUNT(plc.person_id) AS comment_like_count
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY f.id
),
forum_members AS (
    SELECT
        f.id AS forum_id,
        COUNT(fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_moderators AS (
    SELECT
        f.id AS forum_id,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person mod ON f.moderator_person_id = mod.id
),
forum_distinct_tags AS (
    SELECT
        forum_id,
        COUNT(DISTINCT tag_id) AS distinct_tag_count
    FROM (
        SELECT
            f.id AS forum_id,
            pt.tag_id
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN post_has_tag_tag pt ON pt.post_id = p.id
        WHERE pt.tag_id IS NOT NULL

        UNION ALL

        SELECT
            f.id AS forum_id,
            ct.tag_id
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN comment c ON c.parent_post_id = p.id
        LEFT JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
        WHERE ct.tag_id IS NOT NULL
    ) tags
    GROUP BY forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    fm.moderator_first_name,
    fm.moderator_last_name,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fpl.post_like_count, 0) AS post_like_count,
    COALESCE(fcl.comment_like_count, 0) AS comment_like_count,
    COALESCE(fmb.member_count, 0) AS member_count,
    COALESCE(ft.distinct_tag_count, 0) AS distinct_tag_count,
    (COALESCE(fp.post_count, 0) + COALESCE(fc.comment_count, 0) + COALESCE(fpl.post_like_count, 0) + COALESCE(fcl.comment_like_count, 0) + COALESCE(fmb.member_count, 0) + COALESCE(ft.distinct_tag_count, 0)) AS total_engagement
FROM forum f
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_post_likes fpl ON fpl.forum_id = f.id
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = f.id
LEFT JOIN forum_members fmb ON fmb.forum_id = f.id
LEFT JOIN forum_moderators fm ON fm.forum_id = f.id
LEFT JOIN forum_distinct_tags ft ON ft.forum_id = f.id
ORDER BY total_engagement DESC
LIMIT 10
