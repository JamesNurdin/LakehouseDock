WITH
    posts AS (
        SELECT f.id AS forum_id,
               COUNT(p.id) AS total_posts,
               AVG(p.length) AS avg_post_length
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    comments AS (
        SELECT f.id AS forum_id,
               COUNT(c.id) AS total_comments
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN comment c ON c.parent_post_id = p.id
        GROUP BY f.id
    ),
    likes AS (
        SELECT f.id AS forum_id,
               COUNT(plp.person_id) AS total_likes
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN person_likes_post plp ON plp.post_id = p.id
        GROUP BY f.id
    ),
    members AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT fmmp.person_id) AS distinct_member_count
        FROM forum f
        LEFT JOIN forum_has_member_person fmmp ON fmmp.forum_id = f.id
        GROUP BY f.id
    ),
    forum_tags AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT fht.tag_id) AS distinct_forum_tag_count
        FROM forum f
        LEFT JOIN forum_has_tag_tag fht ON fht.forum_id = f.id
        GROUP BY f.id
    ),
    post_tags AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT pht.tag_id) AS distinct_post_tag_count
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN post_has_tag_tag pht ON pht.post_id = p.id
        GROUP BY f.id
    ),
    post_countries AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT pl.id) AS distinct_post_country_count
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN place pl ON p.location_country_id = pl.id
        GROUP BY f.id
    ),
    comment_countries AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT pl.id) AS distinct_comment_country_count
        FROM forum f
        LEFT JOIN post p ON p.container_forum_id = f.id
        LEFT JOIN comment c ON c.parent_post_id = p.id
        LEFT JOIN place pl ON c.location_country_id = pl.id
        GROUP BY f.id
    ),
    moderators AS (
        SELECT f.id AS forum_id,
               mod.first_name AS moderator_first_name,
               mod.last_name  AS moderator_last_name
        FROM forum f
        LEFT JOIN person mod ON f.moderator_person_id = mod.id
    )
SELECT
    f.id   AS forum_id,
    f.title AS forum_title,
    mod.moderator_first_name,
    mod.moderator_last_name,
    COALESCE(p.total_posts, 0)                AS total_posts,
    COALESCE(p.avg_post_length, 0)            AS avg_post_length,
    COALESCE(c.total_comments, 0)             AS total_comments,
    COALESCE(l.total_likes, 0)                AS total_likes,
    COALESCE(m.distinct_member_count, 0)      AS distinct_member_count,
    COALESCE(ft.distinct_forum_tag_count, 0)  AS distinct_forum_tag_count,
    COALESCE(pt.distinct_post_tag_count, 0)   AS distinct_post_tag_count,
    COALESCE(pc.distinct_post_country_count, 0)   AS distinct_post_country_count,
    COALESCE(cc.distinct_comment_country_count, 0) AS distinct_comment_country_count
FROM forum f
LEFT JOIN moderators          mod ON mod.forum_id = f.id
LEFT JOIN posts               p   ON p.forum_id   = f.id
LEFT JOIN comments            c   ON c.forum_id   = f.id
LEFT JOIN likes               l   ON l.forum_id   = f.id
LEFT JOIN members             m   ON m.forum_id   = f.id
LEFT JOIN forum_tags          ft  ON ft.forum_id  = f.id
LEFT JOIN post_tags           pt  ON pt.forum_id  = f.id
LEFT JOIN post_countries      pc  ON pc.forum_id  = f.id
LEFT JOIN comment_countries   cc  ON cc.forum_id  = f.id
ORDER BY total_posts DESC
LIMIT 10
