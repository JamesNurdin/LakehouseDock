WITH
    forum_base AS (
        SELECT f.id AS forum_id,
               f.title AS forum_title,
               f.creation_date AS forum_creation_date,
               f.moderator_person_id
        FROM forum f
    ),
    posts_agg AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS total_posts,
               SUM(p.length) AS total_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    post_tags_agg AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT pht.tag_id) AS distinct_post_tags
        FROM post p
        JOIN post_has_tag_tag pht ON pht.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_members_agg AS (
        SELECT fm.forum_id,
               COUNT(DISTINCT fm.person_id) AS distinct_members
        FROM forum_has_member_person fm
        GROUP BY fm.forum_id
    ),
    post_likes_agg AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS total_post_likes
        FROM person_likes_post plp
        JOIN post p ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comments_agg AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT c.id) AS total_comments,
               AVG(c.length) AS avg_comment_length
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comment_likes_agg AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS total_comment_likes
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comment_tags_agg AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT cht.tag_id) AS distinct_comment_tags
        FROM comment_has_tag_tag cht
        JOIN comment c ON cht.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    )
SELECT
    fb.forum_id,
    fb.forum_title,
    COALESCE(pa.total_posts, 0) AS total_posts,
    COALESCE(pa.total_post_length, 0) AS total_post_length,
    COALESCE(pta.distinct_post_tags, 0) AS distinct_post_tags,
    COALESCE(fm.distinct_members, 0) AS distinct_members,
    COALESCE(pl.total_post_likes, 0) AS total_post_likes,
    COALESCE(ca.total_comments, 0) AS total_comments,
    COALESCE(ca.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(ct.distinct_comment_tags, 0) AS distinct_comment_tags
FROM forum_base fb
LEFT JOIN posts_agg pa ON pa.forum_id = fb.forum_id
LEFT JOIN post_tags_agg pta ON pta.forum_id = fb.forum_id
LEFT JOIN forum_members_agg fm ON fm.forum_id = fb.forum_id
LEFT JOIN post_likes_agg pl ON pl.forum_id = fb.forum_id
LEFT JOIN comments_agg ca ON ca.forum_id = fb.forum_id
LEFT JOIN comment_likes_agg cl ON cl.forum_id = fb.forum_id
LEFT JOIN comment_tags_agg ct ON ct.forum_id = fb.forum_id
ORDER BY total_posts DESC, forum_id
LIMIT 100
