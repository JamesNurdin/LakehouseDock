WITH interest_counts AS (
    SELECT
        pit.tag_id,
        COUNT(DISTINCT pit.person_id) AS interested_persons
    FROM person_has_interest_tag pit
    GROUP BY pit.tag_id
),
post_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT p.id) AS num_posts
    FROM tag t
    JOIN forum_has_tag_tag fht ON fht.tag_id = t.id
    JOIN forum f ON f.id = fht.forum_id
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY t.id
),
comment_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT c.id) AS num_comments
    FROM tag t
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    GROUP BY t.id
),
post_like_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT pl.person_id) AS post_likers,
        COUNT(pl.person_id) AS total_post_likes
    FROM tag t
    JOIN forum_has_tag_tag fht ON fht.tag_id = t.id
    JOIN forum f ON f.id = fht.forum_id
    JOIN post p ON p.container_forum_id = f.id
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY t.id
),
comment_like_counts AS (
    SELECT
        t.id AS tag_id,
        COUNT(DISTINCT cl.person_id) AS comment_likers,
        COUNT(cl.person_id) AS total_comment_likes
    FROM tag t
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY t.id
)
SELECT
    t.id,
    t.name,
    COALESCE(pc.num_posts, 0) AS num_posts,
    COALESCE(cc.num_comments, 0) AS num_comments,
    COALESCE(plc.post_likers, 0) AS post_likers,
    COALESCE(clc.comment_likers, 0) AS comment_likers,
    COALESCE(ic.interested_persons, 0) AS interested_persons,
    COALESCE(plc.total_post_likes, 0) AS total_post_likes,
    COALESCE(clc.total_comment_likes, 0) AS total_comment_likes
FROM tag t
LEFT JOIN post_counts pc ON pc.tag_id = t.id
LEFT JOIN comment_counts cc ON cc.tag_id = t.id
LEFT JOIN post_like_counts plc ON plc.tag_id = t.id
LEFT JOIN comment_like_counts clc ON clc.tag_id = t.id
LEFT JOIN interest_counts ic ON ic.tag_id = t.id
ORDER BY num_posts DESC, num_comments DESC
LIMIT 20
