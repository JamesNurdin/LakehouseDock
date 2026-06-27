WITH forum_posts AS (
    SELECT p.container_forum_id AS forum_id,
           p.id AS post_id,
           p.length AS post_length
    FROM post p
),
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           c.id AS comment_id,
           c.length AS comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
),
forum_likes_post AS (
    SELECT p.container_forum_id AS forum_id,
           plp.person_id AS liker_id
    FROM post p
    JOIN person_likes_post plp ON plp.post_id = p.id
),
forum_likes_comment AS (
    SELECT p.container_forum_id AS forum_id,
           plc.person_id AS liker_id
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
),
forum_members AS (
    SELECT fmp.forum_id,
           fmp.person_id AS member_id
    FROM forum_has_member_person fmp
),
forum_tags AS (
    SELECT fht.forum_id,
           fht.tag_id AS tag_id
    FROM forum_has_tag_tag fht
),
member_interests AS (
    SELECT fmp.forum_id,
           pit.tag_id AS interest_tag_id
    FROM forum_has_member_person fmp
    JOIN person p ON fmp.person_id = p.id
    JOIN person_has_interest_tag pit ON pit.person_id = p.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(flpost.like_count, 0) AS post_like_count,
    COALESCE(flcomment.like_count, 0) AS comment_like_count,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ft.tag_count, 0) AS tag_count,
    COALESCE(fi.interest_tag_count, 0) AS member_interest_tag_count
FROM forum f
LEFT JOIN (
    SELECT forum_id,
           COUNT(DISTINCT post_id) AS post_count,
           AVG(post_length) AS avg_post_length
    FROM forum_posts
    GROUP BY forum_id
) fp ON fp.forum_id = f.id
LEFT JOIN (
    SELECT forum_id,
           COUNT(DISTINCT comment_id) AS comment_count,
           AVG(comment_length) AS avg_comment_length
    FROM forum_comments
    GROUP BY forum_id
) fc ON fc.forum_id = f.id
LEFT JOIN (
    SELECT forum_id,
           COUNT(DISTINCT member_id) AS member_count
    FROM forum_members
    GROUP BY forum_id
) fm ON fm.forum_id = f.id
LEFT JOIN (
    SELECT forum_id,
           COUNT(DISTINCT liker_id) AS like_count
    FROM forum_likes_post
    GROUP BY forum_id
) flpost ON flpost.forum_id = f.id
LEFT JOIN (
    SELECT forum_id,
           COUNT(DISTINCT liker_id) AS like_count
    FROM forum_likes_comment
    GROUP BY forum_id
) flcomment ON flcomment.forum_id = f.id
LEFT JOIN (
    SELECT forum_id,
           COUNT(DISTINCT tag_id) AS tag_count
    FROM forum_tags
    GROUP BY forum_id
) ft ON ft.forum_id = f.id
LEFT JOIN (
    SELECT forum_id,
           COUNT(DISTINCT interest_tag_id) AS interest_tag_count
    FROM member_interests
    GROUP BY forum_id
) fi ON fi.forum_id = f.id
ORDER BY post_count DESC
LIMIT 100
