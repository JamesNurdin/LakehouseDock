WITH forum_base AS (
    SELECT id AS forum_id,
           title
    FROM forum
),
forum_moderator AS (
    SELECT f.id AS forum_id,
           p.first_name AS moderator_first_name,
           p.last_name  AS moderator_last_name
    FROM forum f
    JOIN person p ON f.moderator_person_id = p.id
),
forum_members AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
forum_posts AS (
    SELECT container_forum_id AS forum_id,
           COUNT(*)                AS post_count,
           SUM(length)             AS total_post_length,
           AVG(length)             AS avg_post_length
    FROM post
    GROUP BY container_forum_id
),
forum_post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*)               AS post_like_count
    FROM post p
    JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*)                AS comment_count,
           SUM(c.length)           AS total_comment_length,
           AVG(c.length)           AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*)               AS comment_like_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY p.container_forum_id
),
forum_tag_counts AS (
    SELECT p.container_forum_id AS forum_id,
           pt.tag_id,
           COUNT(*)               AS tag_usage
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY p.container_forum_id, pt.tag_id
),
forum_top_tag AS (
    SELECT forum_id,
           tag_id      AS top_tag_id,
           tag_usage   AS top_tag_usage
    FROM (
        SELECT forum_id,
               tag_id,
               tag_usage,
               ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage DESC) AS rn
        FROM forum_tag_counts
    )
    WHERE rn = 1
)
SELECT
    fb.forum_id,
    fb.title                         AS forum_title,
    fm.moderator_first_name,
    fm.moderator_last_name,
    COALESCE(fmbr.member_count, 0)   AS member_count,
    COALESCE(fp.post_count, 0)       AS post_count,
    COALESCE(fc.comment_count, 0)    AS comment_count,
    COALESCE(fp.total_post_length, 0) AS total_post_length,
    COALESCE(fp.avg_post_length, 0)   AS avg_post_length,
    COALESCE(fc.total_comment_length, 0) AS total_comment_length,
    COALESCE(fc.avg_comment_length, 0)   AS avg_comment_length,
    COALESCE(fpl.post_like_count, 0)     AS post_like_count,
    COALESCE(fcl.comment_like_count, 0)  AS comment_like_count,
    tt.top_tag_id,
    COALESCE(tt.top_tag_usage, 0)        AS top_tag_usage
FROM forum_base fb
JOIN forum_moderator fm ON fm.forum_id = fb.forum_id
LEFT JOIN forum_members fmbr ON fmbr.forum_id = fb.forum_id
LEFT JOIN forum_posts fp ON fp.forum_id = fb.forum_id
LEFT JOIN forum_post_likes fpl ON fpl.forum_id = fb.forum_id
LEFT JOIN forum_comments fc ON fc.forum_id = fb.forum_id
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = fb.forum_id
LEFT JOIN forum_top_tag tt ON tt.forum_id = fb.forum_id
ORDER BY fb.forum_id
