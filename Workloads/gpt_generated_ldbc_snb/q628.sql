WITH posts_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT plp.person_id) AS post_like_count
    FROM post p
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
tags_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM post p
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    JOIN tag t
        ON t.id = pht.tag_id
    GROUP BY p.container_forum_id
),
comments_agg AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT plc.person_id) AS comment_like_count
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY p.container_forum_id
),
members_agg AS (
    SELECT
        fmp.forum_id AS forum_id,
        COUNT(DISTINCT fmp.person_id) AS member_count
    FROM forum_has_member_person fmp
    GROUP BY fmp.forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(pagg.post_count, 0) AS post_count,
    COALESCE(pagg.avg_post_length, 0) AS avg_post_length,
    COALESCE(pagg.post_like_count, 0) AS post_like_count,
    COALESCE(tagagg.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(cagg.comment_count, 0) AS comment_count,
    COALESCE(cagg.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cagg.comment_like_count, 0) AS comment_like_count,
    COALESCE(magg.member_count, 0) AS member_count
FROM forum f
LEFT JOIN posts_agg pagg
    ON pagg.forum_id = f.id
LEFT JOIN tags_agg tagagg
    ON tagagg.forum_id = f.id
LEFT JOIN comments_agg cagg
    ON cagg.forum_id = f.id
LEFT JOIN members_agg magg
    ON magg.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
