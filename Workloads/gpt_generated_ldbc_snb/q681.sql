WITH forum_info AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        moderator.first_name AS moderator_first_name,
        moderator.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person moderator ON f.moderator_person_id = moderator.id
),
forum_members AS (
    SELECT f.id AS forum_id, fm.person_id AS person_id
    FROM forum f
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    UNION
    SELECT f.id AS forum_id, f.moderator_person_id AS person_id
    FROM forum f
    WHERE f.moderator_person_id IS NOT NULL
),
forum_member_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS member_count
    FROM forum_members
    GROUP BY forum_id
),
forum_posts AS (
    SELECT f.id AS forum_id,
           p.id AS post_id,
           p.length AS post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
),
forum_post_stats AS (
    SELECT forum_id,
           COUNT(DISTINCT post_id) AS post_count,
           AVG(post_length) AS avg_post_length
    FROM forum_posts
    GROUP BY forum_id
),
post_likes AS (
    SELECT f.id AS forum_id,
           plp.person_id AS liker_id,
           plp.post_id AS post_id
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN person_likes_post plp ON plp.post_id = p.id
),
forum_post_like_counts AS (
    SELECT forum_id,
           COUNT(*) AS post_like_count
    FROM post_likes
    GROUP BY forum_id
),
forum_comments AS (
    SELECT f.id AS forum_id,
           c.id AS comment_id,
           c.length AS comment_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
),
forum_comment_stats AS (
    SELECT forum_id,
           COUNT(DISTINCT comment_id) AS comment_count,
           AVG(comment_length) AS avg_comment_length
    FROM forum_comments
    GROUP BY forum_id
),
comment_likes AS (
    SELECT f.id AS forum_id,
           plc.person_id AS liker_id,
           plc.comment_id AS comment_id
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
),
forum_comment_like_counts AS (
    SELECT forum_id,
           COUNT(*) AS comment_like_count
    FROM comment_likes
    GROUP BY forum_id
),
comment_tags AS (
    SELECT f.id AS forum_id,
           cht.tag_id AS tag_id,
           cht.comment_id AS comment_id
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
),
forum_tag_counts AS (
    SELECT forum_id,
           tag_id,
           COUNT(*) AS tag_usage_count
    FROM comment_tags
    GROUP BY forum_id, tag_id
),
forum_top_tags AS (
    SELECT forum_id,
           tag_id,
           tag_usage_count,
           ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_usage_count DESC) AS tag_rank
    FROM forum_tag_counts
)
SELECT
    fi.forum_id,
    fi.forum_title,
    fi.moderator_first_name,
    fi.moderator_last_name,
    COALESCE(fmc.member_count, 0) AS member_count,
    COALESCE(fps.post_count, 0) AS post_count,
    COALESCE(fps.avg_post_length, 0) AS avg_post_length,
    COALESCE(fplc.post_like_count, 0) AS post_like_count,
    COALESCE(fcs.comment_count, 0) AS comment_count,
    COALESCE(fcs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fclc.comment_like_count, 0) AS comment_like_count,
    ft.tag_id,
    ft.tag_usage_count
FROM forum_info fi
LEFT JOIN forum_member_counts fmc ON fmc.forum_id = fi.forum_id
LEFT JOIN forum_post_stats fps ON fps.forum_id = fi.forum_id
LEFT JOIN forum_post_like_counts fplc ON fplc.forum_id = fi.forum_id
LEFT JOIN forum_comment_stats fcs ON fcs.forum_id = fi.forum_id
LEFT JOIN forum_comment_like_counts fclc ON fclc.forum_id = fi.forum_id
LEFT JOIN (
    SELECT forum_id, tag_id, tag_usage_count
    FROM forum_top_tags
    WHERE tag_rank <= 5
) ft ON ft.forum_id = fi.forum_id
ORDER BY fi.forum_id, ft.tag_usage_count DESC
