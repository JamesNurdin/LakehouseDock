WITH forum_comments AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        c.id AS comment_id,
        c.length AS comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
),
forum_aggregates AS (
    SELECT
        fc.forum_id,
        COUNT(DISTINCT fc.comment_id) AS total_comments,
        AVG(fc.comment_length) AS avg_comment_length
    FROM forum_comments fc
    GROUP BY fc.forum_id
),
forum_member_likes AS (
    SELECT
        fc.forum_id,
        fc.comment_id,
        p.id AS liker_person_id
    FROM forum_comments fc
    JOIN person_likes_comment plc ON plc.comment_id = fc.comment_id
    JOIN person p ON p.id = plc.person_id
    JOIN forum_has_member_person fmp ON fmp.forum_id = fc.forum_id AND fmp.person_id = p.id
),
forum_like_aggregates AS (
    SELECT
        fml.forum_id,
        COUNT(*) AS total_likes_by_members
    FROM forum_member_likes fml
    GROUP BY fml.forum_id
),
forum_tag_counts AS (
    SELECT
        fml.forum_id,
        iht.tag_id,
        COUNT(*) AS tag_like_count
    FROM forum_member_likes fml
    JOIN person p ON p.id = fml.liker_person_id
    JOIN person_has_interest_tag iht ON iht.person_id = p.id
    GROUP BY fml.forum_id, iht.tag_id
),
forum_top_tag AS (
    SELECT
        ftc.forum_id,
        ftc.tag_id,
        ftc.tag_like_count,
        ROW_NUMBER() OVER (PARTITION BY ftc.forum_id ORDER BY ftc.tag_like_count DESC) AS rn
    FROM forum_tag_counts ftc
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    fa.total_comments,
    fla.total_likes_by_members,
    fa.avg_comment_length,
    ft.tag_id AS top_interest_tag_id,
    ft.tag_like_count AS top_tag_like_count
FROM forum f
LEFT JOIN person mod ON mod.id = f.moderator_person_id
JOIN forum_aggregates fa ON fa.forum_id = f.id
JOIN forum_like_aggregates fla ON fla.forum_id = f.id
LEFT JOIN forum_top_tag ft ON ft.forum_id = f.id AND ft.rn = 1
ORDER BY fla.total_likes_by_members DESC
LIMIT 10
