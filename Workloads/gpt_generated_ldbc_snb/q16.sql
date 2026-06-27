WITH post_like_tags AS (
    SELECT
        p.container_forum_id AS forum_id,
        tc.id                AS tag_class_id,
        tc.name              AS tag_class_name,
        COUNT(pl.person_id)  AS like_cnt
    FROM post p
    JOIN person_likes_post pl ON p.id = pl.post_id
    JOIN post_has_tag_tag pht   ON p.id = pht.post_id
    JOIN tag t                  ON pht.tag_id = t.id
    JOIN tag_class tc           ON t.type_tag_class_id = tc.id
    GROUP BY p.container_forum_id, tc.id, tc.name
),
comment_like_tags AS (
    SELECT
        p.container_forum_id AS forum_id,
        tc.id                AS tag_class_id,
        tc.name              AS tag_class_name,
        COUNT(cl.person_id)  AS like_cnt
    FROM comment c
    JOIN person_likes_comment cl ON c.id = cl.comment_id
    JOIN comment_has_tag_tag cht  ON c.id = cht.comment_id
    JOIN tag t                    ON cht.tag_id = t.id
    JOIN tag_class tc             ON t.type_tag_class_id = tc.id
    JOIN post p                   ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id, tc.id, tc.name
),
combined_likes AS (
    SELECT forum_id, tag_class_id, tag_class_name, like_cnt FROM post_like_tags
    UNION ALL
    SELECT forum_id, tag_class_id, tag_class_name, like_cnt FROM comment_like_tags
)
SELECT
    f.id          AS forum_id,
    f.title       AS forum_title,
    cl.tag_class_name,
    SUM(cl.like_cnt) AS total_likes
FROM combined_likes cl
JOIN forum f ON cl.forum_id = f.id
GROUP BY f.id, f.title, cl.tag_class_name
ORDER BY total_likes DESC
LIMIT 100
