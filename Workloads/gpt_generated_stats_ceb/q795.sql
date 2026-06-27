WITH
    post_base AS (
        SELECT
            p.id AS post_id,
            p.owneruserid,
            p.lasteditoruserid,
            p.score,
            p.viewcount,
            p.answercount,
            p.commentcount,
            p.favoritecount
        FROM posts p
    ),
    comment_agg AS (
        SELECT
            c.postid AS post_id,
            COUNT(*) AS comment_cnt,
            SUM(c.score) AS comment_score_sum,
            COUNT(DISTINCT c.userid) AS distinct_commenters
        FROM comments c
        GROUP BY c.postid
    ),
    history_agg AS (
        SELECT
            ph.posthistorytypeid AS post_id,
            COUNT(*) AS history_cnt
        FROM posthistory ph
        GROUP BY ph.posthistorytypeid
    ),
    outgoing_links_agg AS (
        SELECT
            pl.postid AS post_id,
            COUNT(*) AS outgoing_links_cnt
        FROM postlinks pl
        GROUP BY pl.postid
    ),
    incoming_links_agg AS (
        SELECT
            pl.relatedpostid AS post_id,
            COUNT(*) AS incoming_links_cnt
        FROM postlinks pl
        GROUP BY pl.relatedpostid
    ),
    tag_agg AS (
        SELECT
            t.excerptpostid AS post_id,
            SUM(t.count) AS tag_total_count
        FROM tags t
        GROUP BY t.excerptpostid
    ),
    owner_user AS (
        SELECT
            u.id AS user_id,
            u.reputation AS reputation
        FROM users u
    ),
    last_editor_user AS (
        SELECT
            u.id AS user_id,
            u.reputation AS reputation
        FROM users u
    ),
    post_metrics AS (
        SELECT
            pb.post_id,
            pb.owneruserid,
            pb.lasteditoruserid,
            pb.score,
            pb.viewcount,
            pb.answercount,
            pb.commentcount,
            pb.favoritecount,
            COALESCE(ca.comment_cnt, 0) AS comment_cnt,
            COALESCE(ca.comment_score_sum, 0) AS comment_score_sum,
            COALESCE(ca.distinct_commenters, 0) AS distinct_commenters,
            COALESCE(ha.history_cnt, 0) AS history_cnt,
            COALESCE(ola.outgoing_links_cnt, 0) AS outgoing_links_cnt,
            COALESCE(ila.incoming_links_cnt, 0) AS incoming_links_cnt,
            COALESCE(ta.tag_total_count, 0) AS tag_total_count,
            ou.reputation AS owner_reputation,
            leu.reputation AS last_editor_reputation
        FROM post_base pb
        LEFT JOIN comment_agg ca ON ca.post_id = pb.post_id
        LEFT JOIN history_agg ha ON ha.post_id = pb.post_id
        LEFT JOIN outgoing_links_agg ola ON ola.post_id = pb.post_id
        LEFT JOIN incoming_links_agg ila ON ila.post_id = pb.post_id
        LEFT JOIN tag_agg ta ON ta.post_id = pb.post_id
        LEFT JOIN owner_user ou ON ou.user_id = pb.owneruserid
        LEFT JOIN last_editor_user leu ON leu.user_id = pb.lasteditoruserid
    ),
    owner_commenters AS (
        SELECT
            p.owneruserid AS owner_user_id,
            COUNT(DISTINCT c.userid) AS distinct_commenters_on_owner_posts
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    owner_agg AS (
        SELECT
            pm.owneruserid AS owner_user_id,
            COUNT(DISTINCT pm.post_id) AS total_posts,
            SUM(pm.score) AS total_post_score,
            SUM(pm.viewcount) AS total_viewcount,
            SUM(pm.answercount) AS total_answer_count,
            SUM(pm.commentcount) AS total_commentcount,
            SUM(pm.comment_cnt) AS total_comment_cnt,
            SUM(pm.comment_score_sum) AS total_comment_score,
            SUM(pm.distinct_commenters) AS total_distinct_commenters_per_post,
            SUM(pm.history_cnt) AS total_history_events,
            SUM(pm.outgoing_links_cnt) AS total_outgoing_links,
            SUM(pm.incoming_links_cnt) AS total_incoming_links,
            SUM(pm.tag_total_count) AS total_tag_count,
            MAX(pm.owner_reputation) AS owner_reputation,
            AVG(pm.last_editor_reputation) AS avg_last_editor_reputation
        FROM post_metrics pm
        GROUP BY pm.owneruserid
    )
SELECT
    oa.owner_user_id,
    oa.owner_reputation,
    oa.total_posts,
    oa.total_post_score,
    oa.total_viewcount,
    oa.total_answer_count,
    oa.total_comment_cnt,
    oa.total_comment_score,
    COALESCE(oc.distinct_commenters_on_owner_posts, 0) AS distinct_commenters_on_owner_posts,
    oa.total_history_events,
    oa.total_outgoing_links,
    oa.total_incoming_links,
    oa.total_tag_count,
    oa.avg_last_editor_reputation,
    (
        oa.total_post_score * 1.0
        + oa.total_viewcount / 100.0
        + oa.total_comment_score * 0.5
        + oa.total_answer_count * 2.0
        + oa.total_outgoing_links * 1.0
        + oa.total_incoming_links * 1.0
        + oa.total_history_events * 0.2
    ) AS engagement_score
FROM owner_agg oa
LEFT JOIN owner_commenters oc ON oc.owner_user_id = oa.owner_user_id
ORDER BY engagement_score DESC
LIMIT 20
