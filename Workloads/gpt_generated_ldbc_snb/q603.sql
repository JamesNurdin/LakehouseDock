WITH
    likes_by_tag AS (
        SELECT
            pht.tag_id AS tag_id,
            COUNT(*) AS total_likes,
            COUNT(DISTINCT plp.person_id) AS distinct_likers,
            COUNT(DISTINCT p.id) AS distinct_posts
        FROM person_likes_post plp
        JOIN post p
            ON plp.post_id = p.id
        JOIN post_has_tag_tag pht
            ON p.id = pht.post_id
        JOIN person per
            ON plp.person_id = per.id
        WHERE per.gender = 'female'
        GROUP BY pht.tag_id
    ),
    comments_by_tag AS (
        SELECT
            pht.tag_id AS tag_id,
            COUNT(*) AS total_comments,
            AVG(c.length) AS avg_comment_length,
            COUNT(DISTINCT p.id) AS distinct_posts,
            COUNT(DISTINCT c.creator_person_id) AS distinct_commenters
        FROM comment c
        JOIN post p
            ON c.parent_post_id = p.id
        JOIN post_has_tag_tag pht
            ON p.id = pht.post_id
        JOIN person per
            ON c.creator_person_id = per.id
        WHERE per.gender = 'female'
        GROUP BY pht.tag_id
    )
SELECT
    COALESCE(l.tag_id, cm.tag_id) AS tag_id,
    COALESCE(l.total_likes, 0) AS total_likes,
    COALESCE(l.distinct_likers, 0) AS distinct_likers,
    COALESCE(l.distinct_posts, 0) AS likes_distinct_posts,
    COALESCE(cm.total_comments, 0) AS total_comments,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cm.distinct_posts, 0) AS comments_distinct_posts,
    COALESCE(cm.distinct_commenters, 0) AS distinct_commenters,
    CASE WHEN COALESCE(l.distinct_posts, 0) > 0
         THEN COALESCE(l.total_likes, 0) * 1.0 / COALESCE(l.distinct_posts, 0)
         ELSE 0 END AS avg_likes_per_post,
    CASE WHEN COALESCE(cm.distinct_posts, 0) > 0
         THEN COALESCE(cm.total_comments, 0) * 1.0 / COALESCE(cm.distinct_posts, 0)
         ELSE 0 END AS avg_comments_per_post
FROM likes_by_tag l
FULL OUTER JOIN comments_by_tag cm
    ON l.tag_id = cm.tag_id
ORDER BY total_likes DESC
LIMIT 10
