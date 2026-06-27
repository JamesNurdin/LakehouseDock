WITH
    members AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT fmp.person_id) AS member_count
        FROM forum f
        JOIN forum_has_member_person fmp
          ON fmp.forum_id = f.id
        GROUP BY f.id
    ),
    posts AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT p.id) AS post_count,
               AVG(p.length) AS avg_post_length
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    tags AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT ftt.tag_id) AS tag_count
        FROM forum f
        JOIN forum_has_tag_tag ftt
          ON ftt.forum_id = f.id
        GROUP BY f.id
    ),
    likes AS (
        SELECT f.id AS forum_id,
               COUNT(plp.person_id) AS total_likes_on_posts
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        JOIN person_likes_post plp
          ON plp.post_id = p.id
        GROUP BY f.id
    ),
    post_counts_per_member AS (
        SELECT f.id AS forum_id,
               p.creator_person_id AS person_id,
               COUNT(p.id) AS post_count
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        GROUP BY f.id, p.creator_person_id
    ),
    top_member AS (
        SELECT pcm.forum_id,
               pcm.person_id,
               pcm.post_count,
               ROW_NUMBER() OVER (PARTITION BY pcm.forum_id ORDER BY pcm.post_count DESC) AS rn
        FROM post_counts_per_member pcm
    ),
    top_member_details AS (
        SELECT tm.forum_id,
               p.first_name,
               p.last_name,
               tm.post_count
        FROM top_member tm
        JOIN person p
          ON p.id = tm.person_id
        WHERE tm.rn = 1
    ),
    moderators AS (
        SELECT f.id AS forum_id,
               p.first_name AS mod_first_name,
               p.last_name AS mod_last_name
        FROM forum f
        JOIN person p
          ON p.id = f.moderator_person_id
    )
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    mod.mod_first_name,
    mod.mod_last_name,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(pst.post_count, 0) AS post_count,
    COALESCE(pst.avg_post_length, 0) AS avg_post_length,
    COALESCE(tg.tag_count, 0) AS tag_count,
    COALESCE(l.total_likes_on_posts, 0) AS total_likes_on_posts,
    tm.first_name AS top_member_first_name,
    tm.last_name AS top_member_last_name,
    tm.post_count AS top_member_post_count
FROM forum f
LEFT JOIN moderators mod
  ON mod.forum_id = f.id
LEFT JOIN members m
  ON m.forum_id = f.id
LEFT JOIN posts pst
  ON pst.forum_id = f.id
LEFT JOIN tags tg
  ON tg.forum_id = f.id
LEFT JOIN likes l
  ON l.forum_id = f.id
LEFT JOIN top_member_details tm
  ON tm.forum_id = f.id
ORDER BY f.id
