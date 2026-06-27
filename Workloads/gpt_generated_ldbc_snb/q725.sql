WITH
    forum_mod AS (
        SELECT
            f.id AS forum_id,
            f.title,
            p.first_name AS moderator_first_name,
            p.last_name AS moderator_last_name
        FROM forum f
        JOIN person p
          ON f.moderator_person_id = p.id
    ),
    post_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(p.id) AS post_count,
            SUM(p.length) AS total_post_length,
            AVG(p.length) AS avg_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    comment_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(c.id) AS comment_count,
            SUM(c.length) AS total_comment_length,
            AVG(c.length) AS avg_comment_length
        FROM comment c
        JOIN post p
          ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    post_like_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(plp.person_id) AS post_like_count
        FROM person_likes_post plp
        JOIN post p
          ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comment_like_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(plc.person_id) AS comment_like_count
        FROM person_likes_comment plc
        JOIN comment c
          ON plc.comment_id = c.id
        JOIN post p
          ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_participants AS (
        SELECT
            p.container_forum_id AS forum_id,
            p.creator_person_id AS person_id
        FROM post p
        UNION ALL
        SELECT
            p.container_forum_id AS forum_id,
            c.creator_person_id AS person_id
        FROM comment c
        JOIN post p
          ON c.parent_post_id = p.id
    ),
    participant_stats AS (
        SELECT
            forum_id,
            COUNT(DISTINCT person_id) AS participant_count
        FROM forum_participants
        GROUP BY forum_id
    )
SELECT
    fm.forum_id,
    fm.title,
    fm.moderator_first_name,
    fm.moderator_last_name,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_length, 0) AS total_post_length,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_length, 0) AS total_comment_length,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pls.post_like_count, 0) AS post_like_count,
    COALESCE(cls.comment_like_count, 0) AS comment_like_count,
    COALESCE(part.participant_count, 0) AS participant_count
FROM forum_mod fm
LEFT JOIN post_stats ps
  ON fm.forum_id = ps.forum_id
LEFT JOIN comment_stats cs
  ON fm.forum_id = cs.forum_id
LEFT JOIN post_like_stats pls
  ON fm.forum_id = pls.forum_id
LEFT JOIN comment_like_stats cls
  ON fm.forum_id = cls.forum_id
LEFT JOIN participant_stats part
  ON fm.forum_id = part.forum_id
ORDER BY fm.forum_id
