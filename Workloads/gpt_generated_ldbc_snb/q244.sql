/*
  Analytical query: For each forum that has at least one tag belonging to the
  tag‑class named 'Technology', count the number of posts and comments that are
  associated with those forums, together with the number of distinct creators
  of the posts and comments. Results are ordered by the total amount of content
  (posts + comments) and limited to the top 10 forums.
*/
WITH forum_tags AS (
    SELECT DISTINCT
        f.id   AS forum_id,
        f.title AS forum_title,
        tc.id  AS tag_class_id,
        tc.name AS tag_class_name
    FROM forum f
    JOIN forum_has_tag_tag fht
        ON f.id = fht.forum_id
    JOIN tag t
        ON fht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    WHERE tc.name = 'Technology'
),
post_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id)               AS post_cnt,
        COUNT(DISTINCT p.creator_person_id) AS post_creator_cnt
    FROM post p
    JOIN forum_tags ft
        ON p.container_forum_id = ft.forum_id
    GROUP BY p.container_forum_id
),
comment_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id)               AS comment_cnt,
        COUNT(DISTINCT c.creator_person_id) AS comment_creator_cnt
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    JOIN forum_tags ft
        ON p.container_forum_id = ft.forum_id
    GROUP BY p.container_forum_id
)
SELECT
    ft.forum_title,
    ft.tag_class_name,
    COALESCE(pc.post_cnt, 0)               AS post_count,
    COALESCE(cc.comment_cnt, 0)            AS comment_count,
    COALESCE(pc.post_creator_cnt, 0)       AS post_creator_count,
    COALESCE(cc.comment_creator_cnt, 0)    AS comment_creator_count,
    COALESCE(pc.post_cnt, 0) + COALESCE(cc.comment_cnt, 0) AS total_content_count
FROM forum_tags ft
LEFT JOIN post_counts pc
    ON ft.forum_id = pc.forum_id
LEFT JOIN comment_counts cc
    ON ft.forum_id = cc.forum_id
ORDER BY total_content_count DESC
LIMIT 10
