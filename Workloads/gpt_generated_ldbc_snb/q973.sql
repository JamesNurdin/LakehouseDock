/*
  Analytical query: forum activity, comment engagement and the most common interest tag among its members.
  The query aggregates per forum:
    • total number of posts
    • total number of comments and average comment length
    • total likes on comments
    • distinct members who liked comments in the forum
    • the top interest tag among forum members (and its count)
  Results are ordered by the number of comments (descending) and limited to the top 10 forums.
*/
WITH forum_members AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           fmp.person_id AS member_id
    FROM forum f
    JOIN forum_has_member_person fmp
        ON fmp.forum_id = f.id
),

forum_posts AS (
    SELECT f.id AS forum_id,
           po.id AS post_id
    FROM forum f
    JOIN post po
        ON po.container_forum_id = f.id
),

forum_comments AS (
    SELECT fp.forum_id,
           c.id AS comment_id,
           c.length AS comment_length
    FROM forum_posts fp
    JOIN comment c
        ON c.parent_post_id = fp.post_id
),

comment_likes AS (
    SELECT fc.forum_id,
           plc.person_id AS liker_id,
           plc.comment_id
    FROM forum_comments fc
    JOIN person_likes_comment plc
        ON plc.comment_id = fc.comment_id
),

member_comment_likes AS (
    SELECT cl.forum_id,
           cl.liker_id
    FROM comment_likes cl
    JOIN forum_members fm
        ON fm.forum_id = cl.forum_id
       AND fm.member_id = cl.liker_id
),

member_tags AS (
    SELECT fm.forum_id,
           pht.tag_id
    FROM forum_members fm
    JOIN person_has_interest_tag pht
        ON pht.person_id = fm.member_id
),

tag_counts AS (
    SELECT mt.forum_id,
           mt.tag_id,
           COUNT(*) AS tag_count,
           ROW_NUMBER() OVER (PARTITION BY mt.forum_id ORDER BY COUNT(*) DESC) AS tag_rank
    FROM member_tags mt
    GROUP BY mt.forum_id, mt.tag_id
),

top_tags AS (
    SELECT forum_id,
           tag_id,
           tag_count
    FROM tag_counts
    WHERE tag_rank = 1
),

posts_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT post_id) AS total_posts
    FROM forum_posts
    GROUP BY forum_id
),

comments_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT comment_id) AS total_comments,
           AVG(comment_length) AS avg_comment_length
    FROM forum_comments
    GROUP BY forum_id
),

comment_likes_agg AS (
    SELECT forum_id,
           COUNT(*) AS total_comment_likes
    FROM comment_likes
    GROUP BY forum_id
),

member_likers_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT liker_id) AS distinct_member_likers
    FROM member_comment_likes
    GROUP BY forum_id
),

forum_info AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title
    FROM forum f
)

SELECT
    fi.forum_id,
    fi.forum_title,
    COALESCE(pa.total_posts, 0)               AS total_posts,
    COALESCE(ca.total_comments, 0)            AS total_comments,
    ca.avg_comment_length                     AS avg_comment_length,
    COALESCE(clpa.total_comment_likes, 0)     AS total_comment_likes,
    COALESCE(mla.distinct_member_likers, 0)   AS distinct_member_likers,
    tt.tag_id                                 AS top_member_interest_tag,
    tt.tag_count                              AS top_member_interest_tag_count
FROM forum_info fi
LEFT JOIN posts_agg pa
    ON pa.forum_id = fi.forum_id
LEFT JOIN comments_agg ca
    ON ca.forum_id = fi.forum_id
LEFT JOIN comment_likes_agg clpa
    ON clpa.forum_id = fi.forum_id
LEFT JOIN member_likers_agg mla
    ON mla.forum_id = fi.forum_id
LEFT JOIN top_tags tt
    ON tt.forum_id = fi.forum_id
ORDER BY total_comments DESC
LIMIT 10
