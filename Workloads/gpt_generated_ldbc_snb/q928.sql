WITH
    forum_moderators AS (
        SELECT f.id AS forum_id,
               f.title AS forum_title,
               p.id AS moderator_id,
               p.first_name AS moderator_first_name,
               p.last_name AS moderator_last_name
        FROM forum f
        JOIN person p ON f.moderator_person_id = p.id
    ),
    post_metrics AS (
        SELECT f.id AS forum_id,
               COUNT(p.id) AS post_count,
               AVG(p.length) AS avg_post_length
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    comment_metrics AS (
        SELECT f.id AS forum_id,
               COUNT(c.id) AS comment_count
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN comment c ON c.parent_post_id = p.id
        GROUP BY f.id
    ),
    like_metrics AS (
        SELECT f.id AS forum_id,
               COUNT(plp.person_id) AS total_likes,
               COUNT(DISTINCT plp.person_id) AS distinct_likers
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN person_likes_post plp ON plp.post_id = p.id
        GROUP BY f.id
    ),
    member_metrics AS (
        SELECT f.id AS forum_id,
               COUNT(fhm.person_id) AS member_count
        FROM forum f
        JOIN forum_has_member_person fhm ON fhm.forum_id = f.id
        GROUP BY f.id
    ),
    member_tag_counts AS (
        SELECT f.id AS forum_id,
               pht.tag_id AS tag_id,
               COUNT(*) AS tag_count
        FROM forum f
        JOIN forum_has_member_person fhm ON fhm.forum_id = f.id
        JOIN person p ON fhm.person_id = p.id
        JOIN person_has_interest_tag pht ON pht.person_id = p.id
        GROUP BY f.id, pht.tag_id
    ),
    top_tag_per_forum AS (
        SELECT forum_id,
               tag_id AS top_tag_id,
               tag_count AS top_tag_count
        FROM (
            SELECT forum_id,
                   tag_id,
                   tag_count,
                   ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_count DESC) AS rn
            FROM member_tag_counts
        )
        WHERE rn = 1
    )
SELECT fm.forum_id,
       fm.forum_title,
       fm.moderator_id,
       fm.moderator_first_name,
       fm.moderator_last_name,
       COALESCE(pm.post_count, 0) AS post_count,
       COALESCE(pm.avg_post_length, 0) AS avg_post_length,
       COALESCE(cm.comment_count, 0) AS comment_count,
       COALESCE(mm.member_count, 0) AS member_count,
       COALESCE(lm.total_likes, 0) AS total_likes,
       COALESCE(lm.distinct_likers, 0) AS distinct_likers,
       COALESCE(tt.top_tag_id, NULL) AS top_tag_id,
       COALESCE(tt.top_tag_count, 0) AS top_tag_count
FROM forum_moderators fm
LEFT JOIN post_metrics pm ON pm.forum_id = fm.forum_id
LEFT JOIN comment_metrics cm ON cm.forum_id = fm.forum_id
LEFT JOIN like_metrics lm ON lm.forum_id = fm.forum_id
LEFT JOIN member_metrics mm ON mm.forum_id = fm.forum_id
LEFT JOIN top_tag_per_forum tt ON tt.forum_id = fm.forum_id
ORDER BY (COALESCE(pm.post_count, 0) + COALESCE(cm.comment_count, 0) + COALESCE(lm.total_likes, 0)) DESC
LIMIT 10
