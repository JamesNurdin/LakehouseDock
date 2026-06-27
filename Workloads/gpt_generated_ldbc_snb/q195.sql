WITH
    forum_posts AS (
        SELECT
            f.id AS forum_id,
            COUNT(p.id) AS post_count,
            AVG(p.length) AS avg_post_length
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    forum_comments AS (
        SELECT
            f.id AS forum_id,
            COUNT(c.id) AS comment_count,
            AVG(c.length) AS avg_comment_length
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN comment c ON c.parent_post_id = p.id
        GROUP BY f.id
    ),
    forum_post_likes AS (
        SELECT
            f.id AS forum_id,
            COUNT(pl.person_id) AS post_like_count
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN person_likes_post pl ON pl.post_id = p.id
        GROUP BY f.id
    ),
    forum_comment_likes AS (
        SELECT
            f.id AS forum_id,
            COUNT(cl.person_id) AS comment_like_count
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN comment c ON c.parent_post_id = p.id
        JOIN person_likes_comment cl ON cl.comment_id = c.id
        GROUP BY f.id
    ),
    forum_members AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum f
        JOIN forum_has_member_person fm ON fm.forum_id = f.id
        GROUP BY f.id
    ),
    forum_member_tags AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT t.tag_id) AS distinct_member_tag_count
        FROM forum f
        JOIN forum_has_member_person fm ON fm.forum_id = f.id
        JOIN person p ON fm.person_id = p.id
        JOIN person_has_interest_tag t ON t.person_id = p.id
        GROUP BY f.id
    ),
    forum_member_post_likers AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT pl.person_id) AS member_post_liker_count
        FROM forum f
        JOIN forum_has_member_person fm ON fm.forum_id = f.id
        JOIN person p ON fm.person_id = p.id
        JOIN person_likes_post pl ON pl.person_id = p.id
        JOIN post po ON po.id = pl.post_id
        WHERE po.container_forum_id = f.id
        GROUP BY f.id
    ),
    forum_member_comment_likers AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT cl.person_id) AS member_comment_liker_count
        FROM forum f
        JOIN forum_has_member_person fm ON fm.forum_id = f.id
        JOIN person p ON fm.person_id = p.id
        JOIN person_likes_comment cl ON cl.person_id = p.id
        JOIN comment c ON c.id = cl.comment_id
        JOIN post po ON po.id = c.parent_post_id
        WHERE po.container_forum_id = f.id
        GROUP BY f.id
    )
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    f.moderator_person_id AS moderator_id,
    COALESCE(fp.post_count, 0) AS total_posts,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(fc.comment_count, 0) AS total_comments,
    COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fpl.post_like_count, 0) AS total_post_likes,
    COALESCE(fcl.comment_like_count, 0) AS total_comment_likes,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(fmt.distinct_member_tag_count, 0) AS distinct_member_tag_count,
    COALESCE(fmpl.member_post_liker_count, 0) AS member_post_liker_count,
    COALESCE(fmcl.member_comment_liker_count, 0) AS member_comment_liker_count
FROM forum f
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_post_likes fpl ON fpl.forum_id = f.id
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = f.id
LEFT JOIN forum_members fm ON fm.forum_id = f.id
LEFT JOIN forum_member_tags fmt ON fmt.forum_id = f.id
LEFT JOIN forum_member_post_likers fmpl ON fmpl.forum_id = f.id
LEFT JOIN forum_member_comment_likers fmcl ON fmcl.forum_id = f.id
ORDER BY total_posts DESC
LIMIT 100
