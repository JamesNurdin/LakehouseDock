WITH tag_post AS (
    SELECT
        t.id AS tag_id,
        t.count AS tag_count,
        p.id AS post_id,
        p.owneruserid,
        p.viewcount,
        p.score,
        p.answercount,
        p.commentcount
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
),
vote_agg AS (
    SELECT
        v.postid,
        COUNT(*) AS vote_count
    FROM votes v
    GROUP BY v.postid
),
comment_agg AS (
    SELECT
        c.postid,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.postid
),
badge_agg AS (
    SELECT
        b.userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
history_agg AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS history_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
link_agg AS (
    SELECT
        post_id,
        SUM(cnt) AS link_count
    FROM (
        SELECT
            pl.postid AS post_id,
            COUNT(*) AS cnt
        FROM postlinks pl
        GROUP BY pl.postid
        UNION ALL
        SELECT
            pl.relatedpostid AS post_id,
            COUNT(*) AS cnt
        FROM postlinks pl
        GROUP BY pl.relatedpostid
    ) t
    GROUP BY post_id
)
SELECT
    tp.tag_id,
    tp.tag_count,
    tp.viewcount,
    tp.score,
    tp.answercount,
    tp.commentcount,
    COALESCE(v.vote_count, 0) AS total_votes,
    COALESCE(c.comment_count, 0) AS total_comments,
    COALESCE(b.badge_count, 0) AS owner_badge_count,
    COALESCE(h.history_count, 0) AS post_history_count,
    COALESCE(l.link_count, 0) AS post_link_count
FROM tag_post tp
LEFT JOIN vote_agg v ON v.postid = tp.post_id
LEFT JOIN comment_agg c ON c.postid = tp.post_id
LEFT JOIN badge_agg b ON b.userid = tp.owneruserid
LEFT JOIN history_agg h ON h.post_id = tp.post_id
LEFT JOIN link_agg l ON l.post_id = tp.post_id
ORDER BY tp.tag_count DESC, tp.tag_id
