WITH post_stats AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS post_count,
           SUM(length) AS total_post_length,
           AVG(length) AS avg_post_length
    FROM post
    GROUP BY creator_person_id
),
comment_stats AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS comment_count,
           SUM(length) AS total_comment_length,
           AVG(length) AS avg_comment_length
    FROM comment
    GROUP BY creator_person_id
),
like_post_stats AS (
    SELECT person_id,
           COUNT(*) AS liked_post_count,
           COUNT(DISTINCT post_id) AS distinct_liked_posts
    FROM person_likes_post
    GROUP BY person_id
),
like_comment_stats AS (
    SELECT person_id,
           COUNT(*) AS liked_comment_count,
           COUNT(DISTINCT comment_id) AS distinct_liked_comments
    FROM person_likes_comment
    GROUP BY person_id
),
friend_stats AS (
    SELECT person1_id AS person_id,
           COUNT(DISTINCT person2_id) AS friend_count
    FROM person_knows_person
    GROUP BY person1_id
),
interest_stats AS (
    SELECT person_id,
           COUNT(DISTINCT tag_id) AS interest_count
    FROM person_has_interest_tag
    GROUP BY person_id
)
SELECT p.id,
       p.first_name,
       p.last_name,
       COALESCE(ps.post_count, 0)                AS post_count,
       COALESCE(ps.total_post_length, 0)         AS total_post_length,
       COALESCE(ps.avg_post_length, 0)           AS avg_post_length,
       COALESCE(cs.comment_count, 0)             AS comment_count,
       COALESCE(cs.total_comment_length, 0)      AS total_comment_length,
       COALESCE(cs.avg_comment_length, 0)        AS avg_comment_length,
       COALESCE(lps.liked_post_count, 0)         AS liked_post_count,
       COALESCE(lps.distinct_liked_posts, 0)    AS distinct_liked_posts,
       COALESCE(lcs.liked_comment_count, 0)      AS liked_comment_count,
       COALESCE(lcs.distinct_liked_comments, 0) AS distinct_liked_comments,
       COALESCE(fs.friend_count, 0)              AS friend_count,
       COALESCE(i.interest_count, 0)             AS interest_count
FROM person p
LEFT JOIN post_stats ps       ON p.id = ps.person_id
LEFT JOIN comment_stats cs    ON p.id = cs.person_id
LEFT JOIN like_post_stats lps ON p.id = lps.person_id
LEFT JOIN like_comment_stats lcs ON p.id = lcs.person_id
LEFT JOIN friend_stats fs     ON p.id = fs.person_id
LEFT JOIN interest_stats i    ON p.id = i.person_id
ORDER BY p.id
LIMIT 100
