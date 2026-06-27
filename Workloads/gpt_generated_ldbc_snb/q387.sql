WITH forum_comments AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        c.id AS comment_id,
        c.length AS comment_length
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    JOIN forum f
        ON p.container_forum_id = f.id
),
forum_comment_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT comment_id) AS total_comments,
        AVG(comment_length) AS avg_comment_length_all
    FROM forum_comments
    GROUP BY forum_id
),
member_comment_likes AS (
    SELECT
        f.id AS forum_id,
        c.id AS comment_id,
        c.length AS comment_length,
        plc.person_id AS liker_person_id
    FROM forum_has_member_person fmp
    JOIN forum f
        ON fmp.forum_id = f.id
    JOIN person_likes_comment plc
        ON plc.person_id = fmp.person_id
    JOIN comment c
        ON plc.comment_id = c.id
    JOIN post p
        ON c.parent_post_id = p.id
    WHERE p.container_forum_id = f.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    fcc.total_comments,
    fcc.avg_comment_length_all,
    mcl.total_member_comment_likes,
    mcl.distinct_comments_liked,
    mcl.avg_comment_length_liked,
    mcl.total_member_comment_likes / NULLIF(mcl.distinct_comments_liked, 0) AS avg_likes_per_comment,
    mcl.distinct_comments_liked / NULLIF(fcc.total_comments, 0) AS liked_comment_ratio
FROM forum_comment_counts fcc
JOIN forum f
    ON fcc.forum_id = f.id
JOIN (
    SELECT
        forum_id,
        COUNT(*) AS total_member_comment_likes,
        COUNT(DISTINCT comment_id) AS distinct_comments_liked,
        AVG(comment_length) AS avg_comment_length_liked
    FROM member_comment_likes
    GROUP BY forum_id
) mcl
    ON mcl.forum_id = fcc.forum_id
ORDER BY total_member_comment_likes DESC
LIMIT 10
