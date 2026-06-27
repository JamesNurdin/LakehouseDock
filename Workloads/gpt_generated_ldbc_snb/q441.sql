/*
  Analytical query: For forums whose moderator is a female, compute various engagement metrics
  – number of posts, number of comments, average comment length, distinct commenters,
    total likes on comments, number of forum members, and the top 3 most‑used tags in
    comments (by usage count). Results are ordered by comment volume and limited to the
    top 10 forums.
*/
WITH female_moderated_forums AS (
    SELECT f.id   AS forum_id,
           f.title
    FROM   forum f
    JOIN   person p ON f.moderator_person_id = p.id
    WHERE  p.gender = 'female'
),
forum_stats AS (
    SELECT
        fmf.forum_id,
        fmf.title,
        COUNT(DISTINCT p.id)                     AS num_posts,
        COUNT(c.id)                              AS num_comments,
        AVG(c.length)                            AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id)      AS num_commenters,
        COUNT(plc.person_id)                     AS total_comment_likes
    FROM   female_moderated_forums fmf
    LEFT JOIN post p               ON p.container_forum_id = fmf.forum_id
    LEFT JOIN comment c            ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY fmf.forum_id, fmf.title
),
forum_members AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS num_members
    FROM   forum_has_member_person fm
    JOIN   female_moderated_forums fmf ON fm.forum_id = fmf.forum_id
    GROUP BY fm.forum_id
),
forum_tag_counts AS (
    SELECT
        fmf.forum_id,
        t.id   AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS tag_usage
    FROM   female_moderated_forums fmf
    JOIN   post p               ON p.container_forum_id = fmf.forum_id
    JOIN   comment c            ON c.parent_post_id = p.id
    JOIN   comment_has_tag_tag ct ON ct.comment_id = c.id
    JOIN   tag t                ON t.id = ct.tag_id
    GROUP BY fmf.forum_id, t.id, t.name
),
forum_top_tags AS (
    SELECT
        forum_id,
        tag_name,
        tag_usage,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage DESC) AS rn
    FROM   forum_tag_counts
)
SELECT
    fs.forum_id,
    fs.title,
    fs.num_posts,
    fs.num_comments,
    fs.avg_comment_length,
    fs.num_commenters,
    fs.total_comment_likes,
    fm.num_members,
    ARRAY_AGG(ftt.tag_name ORDER BY ftt.tag_usage DESC)
        FILTER (WHERE ftt.rn <= 3) AS top_3_tags
FROM   forum_stats fs
LEFT JOIN forum_members fm   ON fm.forum_id = fs.forum_id
LEFT JOIN forum_top_tags ftt ON ftt.forum_id = fs.forum_id
GROUP BY
    fs.forum_id,
    fs.title,
    fs.num_posts,
    fs.num_comments,
    fs.avg_comment_length,
    fs.num_commenters,
    fs.total_comment_likes,
    fm.num_members
ORDER BY fs.num_comments DESC
LIMIT 10
