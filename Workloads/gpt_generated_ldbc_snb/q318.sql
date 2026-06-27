/*
  Analytical query: For each forum, compute the number of comments, total likes on those comments,
  average comment length, and the count of distinct forum members who authored comments.
  The results are broken down by the gender of the comment creator.
*/
WITH comment_stats AS (
    SELECT
        f.id                     AS forum_id,
        f.title                  AS forum_title,
        creator.gender           AS creator_gender,
        c.id                     AS comment_id,
        c.length                 AS comment_length,
        creator.id               AS creator_id,
        COUNT(plc.person_id)     AS like_cnt
    FROM forum f
    -- posts that belong to the forum
    JOIN post p
        ON p.container_forum_id = f.id
    -- comments that belong to those posts
    JOIN comment c
        ON c.parent_post_id = p.id
    -- person who created the comment
    JOIN person creator
        ON creator.id = c.creator_person_id
    -- likes on the comment (left join to keep comments with zero likes)
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    -- keep only comment creators that are members of the forum
    JOIN forum_has_member_person fmp
        ON fmp.forum_id = f.id
        AND fmp.person_id = creator.id
    GROUP BY
        f.id,
        f.title,
        creator.gender,
        c.id,
        c.length,
        creator.id
)
SELECT
    forum_id,
    forum_title,
    creator_gender,
    COUNT(comment_id)               AS comment_count,
    SUM(like_cnt)                   AS total_likes,
    AVG(comment_length)             AS avg_comment_length,
    COUNT(DISTINCT creator_id)      AS distinct_member_commenters
FROM comment_stats
GROUP BY
    forum_id,
    forum_title,
    creator_gender
ORDER BY
    total_likes DESC,
    forum_id
LIMIT 100
