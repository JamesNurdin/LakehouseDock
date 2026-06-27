/*
  Analytical query – summary of activity for each forum.
  It reports the number of posts, comments, likes, members, tags, average lengths
  and the moderator’s name.
*/
WITH forum_stats AS (
    SELECT
        f.id                                         AS forum_id,
        f.title                                      AS forum_title,
        modp.first_name                              AS moderator_first_name,
        modp.last_name                               AS moderator_last_name,
        COUNT(DISTINCT p.id)                         AS num_posts,
        COUNT(DISTINCT c.id)                         AS num_comments,
        AVG(p.length)                                AS avg_post_length,
        AVG(c.length)                                AS avg_comment_length,
        COUNT(plp.person_id)                         AS total_post_likes,
        COUNT(plc.person_id)                         AS total_comment_likes,
        COUNT(DISTINCT fm.person_id)                 AS num_members,
        COUNT(DISTINCT ft.tag_id)                    AS num_tags
    FROM forum f
    LEFT JOIN person modp
        ON modp.id = f.moderator_person_id               -- forum moderator
    LEFT JOIN post p
        ON p.container_forum_id = f.id                  -- posts in the forum
    LEFT JOIN comment c
        ON c.parent_post_id = p.id                      -- comments on those posts
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id                           -- likes on posts
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id                        -- likes on comments
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id                           -- forum members
    LEFT JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id                           -- forum tags
    GROUP BY f.id, f.title, modp.first_name, modp.last_name
)
SELECT
    forum_id,
    forum_title,
    moderator_first_name,
    moderator_last_name,
    num_posts,
    num_comments,
    avg_post_length,
    avg_comment_length,
    total_post_likes,
    total_comment_likes,
    num_members,
    num_tags
FROM forum_stats
ORDER BY forum_id
