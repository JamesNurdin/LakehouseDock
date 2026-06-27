WITH
    -- Members of each forum
    forum_members AS (
        SELECT fhm.forum_id,
               fhm.person_id
        FROM forum_has_member_person fhm
    ),
    -- Posts belonging to each forum
    forum_posts AS (
        SELECT p.container_forum_id AS forum_id,
               p.id                AS post_id
        FROM post p
    ),
    -- Number of distinct members per forum
    member_counts AS (
        SELECT forum_id,
               COUNT(DISTINCT person_id) AS member_count
        FROM forum_members
        GROUP BY forum_id
    ),
    -- Number of distinct posts per forum
    post_counts AS (
        SELECT forum_id,
               COUNT(DISTINCT post_id) AS post_count
        FROM forum_posts
        GROUP BY forum_id
    ),
    -- Total distinct likes on posts per forum
    post_like_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT plp.person_id) AS post_like_count
        FROM person_likes_post plp
        JOIN post p ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    -- Number of distinct comments (directly on posts) per forum
    comment_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT c.id) AS comment_count
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    -- Total distinct likes on comments per forum
    comment_like_counts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(DISTINCT plc.person_id) AS comment_like_count
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    -- Distinct interest‑tags held by members of each forum
    member_interest_tags AS (
        SELECT fm.forum_id,
               COUNT(DISTINCT iht.tag_id) AS distinct_interest_tag_count
        FROM forum_members fm
        JOIN person p ON fm.person_id = p.id
        JOIN person_has_interest_tag iht ON iht.person_id = p.id
        GROUP BY fm.forum_id
    )
SELECT
    f.id   AS forum_id,
    f.title AS forum_title,
    COALESCE(mc.member_count, 0)                     AS member_count,
    COALESCE(pc.post_count, 0)                       AS post_count,
    COALESCE(cc.comment_count, 0)                    AS comment_count,
    COALESCE(plc.post_like_count, 0)                AS total_post_likes,
    COALESCE(clc.comment_like_count, 0)             AS total_comment_likes,
    COALESCE(mit.distinct_interest_tag_count, 0)    AS distinct_interest_tags_of_members,
    CASE WHEN COALESCE(pc.post_count, 0) = 0 THEN 0
         ELSE COALESCE(plc.post_like_count, 0) * 1.0 / COALESCE(pc.post_count, 0)
    END                                              AS avg_likes_per_post,
    CASE WHEN COALESCE(cc.comment_count, 0) = 0 THEN 0
         ELSE COALESCE(clc.comment_like_count, 0) * 1.0 / COALESCE(cc.comment_count, 0)
    END                                              AS avg_likes_per_comment
FROM forum f
LEFT JOIN member_counts mc      ON f.id = mc.forum_id
LEFT JOIN post_counts pc        ON f.id = pc.forum_id
LEFT JOIN comment_counts cc     ON f.id = cc.forum_id
LEFT JOIN post_like_counts plc  ON f.id = plc.forum_id
LEFT JOIN comment_like_counts clc ON f.id = clc.forum_id
LEFT JOIN member_interest_tags mit ON f.id = mit.forum_id
ORDER BY f.id
