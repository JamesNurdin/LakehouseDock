WITH forum_members AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fmp.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fmp ON fmp.forum_id = f.id
    GROUP BY f.id
),
forum_tags AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fht.tag_id) AS tag_count
    FROM forum f
    JOIN forum_has_tag_tag fht ON fht.forum_id = f.id
    GROUP BY f.id
),
forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length,
           COUNT(DISTINCT c.creator_person_id) AS distinct_commenters
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_comment_likes AS (
    SELECT f.id AS forum_id,
           COUNT(plc.person_id) AS comment_like_count,
           COUNT(DISTINCT plc.person_id) AS distinct_comment_likers
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY f.id
)
SELECT f.id,
       f.title,
       f.creation_date,
       COALESCE(fm.member_count, 0) AS member_count,
       COALESCE(ft.tag_count, 0) AS tag_count,
       COALESCE(fp.post_count, 0) AS post_count,
       COALESCE(fp.avg_post_length, 0) AS avg_post_length,
       COALESCE(fc.comment_count, 0) AS comment_count,
       COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(fc.distinct_commenters, 0) AS distinct_commenters,
       COALESCE(cl.comment_like_count, 0) AS comment_like_count,
       COALESCE(cl.distinct_comment_likers, 0) AS distinct_comment_likers
FROM forum f
LEFT JOIN forum_members fm ON fm.forum_id = f.id
LEFT JOIN forum_tags ft ON ft.forum_id = f.id
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_comment_likes cl ON cl.forum_id = f.id
ORDER BY f.id
