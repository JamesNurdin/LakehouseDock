/*
   Tag‑centric activity report
   – number of posts that carry each tag
   – number of comments on those posts
   – average post length and comment length
   – how many distinct forums and distinct authors are involved per tag
*/
WITH tag_post_data AS (
    SELECT
        t.id   AS tag_id,
        t.name AS tag_name,
        p.id   AS post_id,
        p.length AS post_length,
        p.creator_person_id AS post_creator_id,
        f.id   AS forum_id,
        c.id   AS comment_id,
        c.length AS comment_length
    FROM tag t
    JOIN post_has_tag_tag pht
        ON pht.tag_id = t.id
    JOIN post p
        ON p.id = pht.post_id
    JOIN forum f
        ON f.id = p.container_forum_id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
)
SELECT
    tag_id,
    tag_name,
    COUNT(DISTINCT post_id)               AS post_count,
    AVG(post_length)                      AS avg_post_length,
    COUNT(DISTINCT comment_id)            AS comment_count,
    AVG(comment_length)                   AS avg_comment_length,
    COUNT(DISTINCT forum_id)              AS forum_count,
    COUNT(DISTINCT post_creator_id)       AS distinct_post_creators
FROM tag_post_data
GROUP BY tag_id, tag_name
ORDER BY post_count DESC
LIMIT 20
