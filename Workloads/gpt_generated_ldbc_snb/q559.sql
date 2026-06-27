WITH comment_facts AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id,
        f.id AS forum_id,
        p.gender AS creator_gender
    FROM comment c
    JOIN post pst ON c.parent_post_id = pst.id
    JOIN forum f ON pst.container_forum_id = f.id
    JOIN person p ON c.creator_person_id = p.id
),
comment_like_agg AS (
    SELECT
        cl.comment_id,
        COUNT(DISTINCT cl.person_id) AS like_count
    FROM person_likes_comment cl
    GROUP BY cl.comment_id
),
forum_like_agg AS (
    SELECT
        cf.forum_id,
        SUM(COALESCE(cl.like_count, 0)) AS total_likes
    FROM comment_facts cf
    LEFT JOIN comment_like_agg cl ON cl.comment_id = cf.comment_id
    GROUP BY cf.forum_id
),
forum_tag_agg AS (
    SELECT
        cf.forum_id,
        COUNT(DISTINCT ct.tag_id) AS distinct_tags_used
    FROM comment_facts cf
    LEFT JOIN comment_has_tag_tag ct ON ct.comment_id = cf.comment_id
    GROUP BY cf.forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COUNT(DISTINCT cf.comment_id) AS comment_count,
    AVG(cf.comment_length) AS avg_comment_length,
    COALESCE(fl.total_likes, 0) AS total_likes,
    COALESCE(ft.distinct_tags_used, 0) AS distinct_tags_used,
    COUNT(DISTINCT CASE WHEN cf.creator_gender = 'female' THEN cf.creator_person_id END) AS female_commenters,
    COUNT(DISTINCT CASE WHEN cf.creator_gender = 'male' THEN cf.creator_person_id END) AS male_commenters
FROM forum f
LEFT JOIN comment_facts cf ON cf.forum_id = f.id
LEFT JOIN forum_like_agg fl ON fl.forum_id = f.id
LEFT JOIN forum_tag_agg ft ON ft.forum_id = f.id
GROUP BY f.id, f.title, fl.total_likes, ft.distinct_tags_used
ORDER BY comment_count DESC
LIMIT 10
