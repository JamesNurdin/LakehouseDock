WITH likes_per_forum_tag AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(plp.person_id) AS total_likes
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    JOIN tag t ON t.id = pht.tag_id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY f.id, f.title, t.id, t.name
)
SELECT
    forum_id,
    forum_title,
    tag_id,
    tag_name,
    total_likes
FROM (
    SELECT
        forum_id,
        forum_title,
        tag_id,
        tag_name,
        total_likes,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY total_likes DESC) AS rn
    FROM likes_per_forum_tag
) ranked_tags
WHERE rn <= 5
ORDER BY forum_id, rn
