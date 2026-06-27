WITH
    post_stats AS (
        SELECT
            f.id AS forum_id,
            COUNT(p.id) AS post_count,
            COALESCE(AVG(p.length), 0) AS avg_post_length
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    comment_stats AS (
        SELECT
            f.id AS forum_id,
            COUNT(c.id) AS comment_count,
            COALESCE(AVG(c.length), 0) AS avg_comment_length
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        LEFT JOIN comment c
            ON c.parent_post_id = p.id
        GROUP BY f.id
    ),
    member_stats AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT fm.person_id) AS member_count,
            COUNT(DISTINCT t.id) AS distinct_interest_tag_count,
            COUNT(DISTINCT psu.university_id) AS distinct_university_count
        FROM forum f
        LEFT JOIN forum_has_member_person fm
            ON fm.forum_id = f.id
        LEFT JOIN person per
            ON per.id = fm.person_id
        LEFT JOIN person_has_interest_tag pit
            ON pit.person_id = per.id
        LEFT JOIN tag t
            ON t.id = pit.tag_id
        LEFT JOIN person_study_at_university psu
            ON psu.person_id = per.id
        GROUP BY f.id
    ),
    like_stats AS (
        SELECT
            f.id AS forum_id,
            COUNT(plp.person_id) AS total_likes,
            COUNT(DISTINCT plp.person_id) AS distinct_liker_count
        FROM forum f
        LEFT JOIN post p
            ON p.container_forum_id = f.id
        LEFT JOIN person_likes_post plp
            ON plp.post_id = p.id
        GROUP BY f.id
    )
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ms.member_count, 0) AS member_count,
    COALESCE(ms.distinct_interest_tag_count, 0) AS distinct_interest_tag_count,
    COALESCE(ms.distinct_university_count, 0) AS distinct_university_count,
    COALESCE(ls.total_likes, 0) AS total_likes,
    COALESCE(ls.distinct_liker_count, 0) AS distinct_liker_count
FROM forum f
LEFT JOIN post_stats ps
    ON ps.forum_id = f.id
LEFT JOIN comment_stats cs
    ON cs.forum_id = f.id
LEFT JOIN member_stats ms
    ON ms.forum_id = f.id
LEFT JOIN like_stats ls
    ON ls.forum_id = f.id
ORDER BY post_count DESC, total_likes DESC
LIMIT 10
