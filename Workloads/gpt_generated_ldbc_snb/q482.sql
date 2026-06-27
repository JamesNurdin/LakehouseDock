WITH forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(p.id) AS total_posts
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT f.id AS forum_id,
           COUNT(c.id) AS total_comments,
           AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
post_likes AS (
    SELECT f.id AS forum_id,
           COUNT(pl.person_id) AS total_post_likes
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY f.id
),
comment_likes AS (
    SELECT f.id AS forum_id,
           COUNT(cl.person_id) AS total_comment_likes
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY f.id
),
forum_participants AS (
    SELECT f.id AS forum_id,
           p.creator_person_id AS person_id
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    UNION ALL
    SELECT f.id AS forum_id,
           c.creator_person_id AS person_id
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
),
distinct_participants AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS distinct_participants
    FROM forum_participants
    GROUP BY forum_id
),
participant_tags AS (
    SELECT fp.forum_id,
           pht.tag_id,
           COUNT(*) AS tag_count
    FROM forum_participants fp
    JOIN person_has_interest_tag pht ON pht.person_id = fp.person_id
    GROUP BY fp.forum_id, pht.tag_id
),
ranked_tags AS (
    SELECT forum_id,
           tag_id,
           tag_count,
           ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_count DESC) AS rn
    FROM participant_tags
),
top_tags AS (
    SELECT rt.forum_id,
           ARRAY_AGG(t.name ORDER BY rt.tag_count DESC) AS top_three_tags
    FROM ranked_tags rt
    JOIN tag t ON t.id = rt.tag_id
    WHERE rt.rn <= 3
    GROUP BY rt.forum_id
)
SELECT f.id AS forum_id,
       f.title AS forum_title,
       COALESCE(fp.total_posts, 0) AS total_posts,
       COALESCE(fc.total_comments, 0) AS total_comments,
       COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(pl.total_post_likes, 0) AS total_post_likes,
       COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
       COALESCE(dp.distinct_participants, 0) AS distinct_participants,
       COALESCE(tt.top_three_tags, CAST(ARRAY[] AS ARRAY(VARCHAR))) AS top_three_tags
FROM forum f
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN post_likes pl ON pl.forum_id = f.id
LEFT JOIN comment_likes cl ON cl.forum_id = f.id
LEFT JOIN distinct_participants dp ON dp.forum_id = f.id
LEFT JOIN top_tags tt ON tt.forum_id = f.id
ORDER BY total_posts DESC
LIMIT 10
