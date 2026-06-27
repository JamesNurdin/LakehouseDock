/*
   Analytical query: Top 10 forums by number of comments.
   For each forum we compute:
     • Total distinct comments (and total comment length)
     • Total likes on those comments
     • Number of forum members
     • Number of tags directly attached to the forum
     • Number of distinct tags used in the forum's comments
   The query uses only the allowed tables and join relationships.
*/
WITH forum_comments AS (
    SELECT
        f.id   AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT c.id)            AS comment_count,
        COALESCE(SUM(c.length), 0)      AS total_comment_length
    FROM forum f
    JOIN post p   ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id, f.title
),
forum_comment_likes AS (
    SELECT
        f.id   AS forum_id,
        COUNT(plc.person_id) AS comment_like_count
    FROM forum f
    JOIN post p   ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY f.id
),
forum_members AS (
    SELECT
        f.id   AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_tags AS (
    SELECT
        f.id   AS forum_id,
        COUNT(DISTINCT ft.tag_id) AS forum_tag_count
    FROM forum f
    JOIN forum_has_tag_tag ft ON ft.forum_id = f.id
    GROUP BY f.id
),
forum_comment_tags AS (
    SELECT
        f.id   AS forum_id,
        COUNT(DISTINCT ct.tag_id) AS comment_tag_count
    FROM forum f
    JOIN post p   ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    GROUP BY f.id
)
SELECT
    fc.forum_id,
    fc.forum_title,
    fc.comment_count,
    fc.total_comment_length,
    COALESCE(fcl.comment_like_count, 0) AS comment_like_count,
    COALESCE(fm.member_count, 0)       AS member_count,
    COALESCE(ft.forum_tag_count, 0)    AS forum_tag_count,
    COALESCE(fct.comment_tag_count, 0) AS comment_tag_count
FROM forum_comments fc
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = fc.forum_id
LEFT JOIN forum_members       fm  ON fm.forum_id = fc.forum_id
LEFT JOIN forum_tags          ft  ON ft.forum_id = fc.forum_id
LEFT JOIN forum_comment_tags  fct ON fct.forum_id = fc.forum_id
ORDER BY fc.comment_count DESC
LIMIT 10
