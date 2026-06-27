WITH
    -- Base list of forums (id and title)
    forum_base AS (
        SELECT f.id   AS forum_id,
               f.title AS forum_title
        FROM   forum f
    ),
    -- Aggregates for posts per forum
    post_agg AS (
        SELECT po.container_forum_id               AS forum_id,
               COUNT(DISTINCT po.id)                AS post_count,
               AVG(po.length)                       AS avg_post_length
        FROM   post po
        GROUP BY po.container_forum_id
    ),
    -- Distinct tag count across all posts in a forum
    post_tag_agg AS (
        SELECT po.container_forum_id               AS forum_id,
               COUNT(DISTINCT pt.tag_id)            AS post_tag_count
        FROM   post po
        LEFT JOIN post_has_tag_tag pt
               ON pt.post_id = po.id
        GROUP BY po.container_forum_id
    ),
    -- Comment count per forum
    comment_agg AS (
        SELECT po.container_forum_id               AS forum_id,
               COUNT(DISTINCT co.id)                AS comment_count
        FROM   post po
        LEFT JOIN comment co
               ON co.parent_post_id = po.id
        GROUP BY po.container_forum_id
    ),
    -- Total likes on posts per forum
    post_like_agg AS (
        SELECT po.container_forum_id               AS forum_id,
               COUNT(pl.person_id)                  AS total_post_likes
        FROM   post po
        LEFT JOIN person_likes_post pl
               ON pl.post_id = po.id
        GROUP BY po.container_forum_id
    ),
    -- Total likes on comments per forum
    comment_like_agg AS (
        SELECT po.container_forum_id               AS forum_id,
               COUNT(cl.person_id)                  AS total_comment_likes
        FROM   post po
        LEFT JOIN comment co
               ON co.parent_post_id = po.id
        LEFT JOIN person_likes_comment cl
               ON cl.comment_id = co.id
        GROUP BY po.container_forum_id
    ),
    -- Member counts and members whose interests match forum tags
    member_agg AS (
        SELECT f.id                                                    AS forum_id,
               COUNT(DISTINCT fm.person_id)                             AS member_count,
               COUNT(DISTINCT CASE WHEN pi.person_id IS NOT NULL
                                    THEN fm.person_id END)           AS member_with_interest_match_count
        FROM   forum f
        LEFT JOIN forum_has_member_person fm
               ON fm.forum_id = f.id
        LEFT JOIN person pm
               ON pm.id = fm.person_id
        LEFT JOIN forum_has_tag_tag ft
               ON ft.forum_id = f.id
        LEFT JOIN tag t
               ON t.id = ft.tag_id
        LEFT JOIN person_has_interest_tag pi
               ON pi.person_id = pm.id
              AND pi.tag_id = t.id
        GROUP BY f.id
    ),
    -- Distinct tag count attached directly to a forum
    forum_tag_agg AS (
        SELECT f.id                     AS forum_id,
               COUNT(DISTINCT ft.tag_id) AS forum_tag_count
        FROM   forum f
        LEFT JOIN forum_has_tag_tag ft
               ON ft.forum_id = f.id
        GROUP BY f.id
    )
SELECT
    fb.forum_id,
    fb.forum_title,
    COALESCE(pa.post_count, 0)                     AS post_count,
    COALESCE(ca.comment_count, 0)                 AS comment_count,
    COALESCE(pa.avg_post_length, 0)               AS avg_post_length,
    COALESCE(pla.total_post_likes, 0)             AS total_post_likes,
    COALESCE(cla.total_comment_likes, 0)          AS total_comment_likes,
    COALESCE(ma.member_count, 0)                  AS member_count,
    COALESCE(ma.member_with_interest_match_count, 0) AS member_with_interest_match_count,
    COALESCE(fta.forum_tag_count, 0)              AS forum_tag_count,
    COALESCE(pta.post_tag_count, 0)               AS post_tag_count
FROM   forum_base fb
LEFT JOIN post_agg pa      ON pa.forum_id = fb.forum_id
LEFT JOIN post_tag_agg pta ON pta.forum_id = fb.forum_id
LEFT JOIN comment_agg ca   ON ca.forum_id = fb.forum_id
LEFT JOIN post_like_agg pla ON pla.forum_id = fb.forum_id
LEFT JOIN comment_like_agg cla ON cla.forum_id = fb.forum_id
LEFT JOIN member_agg ma    ON ma.forum_id = fb.forum_id
LEFT JOIN forum_tag_agg fta ON fta.forum_id = fb.forum_id
ORDER BY post_count DESC, forum_id
