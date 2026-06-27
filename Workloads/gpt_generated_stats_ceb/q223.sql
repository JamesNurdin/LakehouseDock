WITH
    user_info AS (
        SELECT
            u.id AS user_id,
            u.reputation,
            u.creationdate,
            u.views,
            u.upvotes,
            u.downvotes
        FROM users u
    ),
    post_owner AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posts_owned,
            SUM(p.score) AS total_post_score,
            SUM(p.viewcount) AS total_viewcount,
            AVG(p.answercount) AS avg_answer_count,
            AVG(p.commentcount) AS avg_comment_count,
            SUM(p.favoritecount) AS total_favorite_count
        FROM posts p
        GROUP BY p.owneruserid
    ),
    post_editor AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS posts_edited
        FROM posts p
        WHERE p.lasteditoruserid IS NOT NULL
        GROUP BY p.lasteditoruserid
    ),
    comment_metrics AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comments_made,
            SUM(c.score) AS total_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    vote_cast AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_cast,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_given
        FROM votes v
        GROUP BY v.userid
    ),
    vote_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badge_metrics AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badges_earned
        FROM badges b
        GROUP BY b.userid
    ),
    posthistory_metrics AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS post_history_entries
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    postlinks_source AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlinks_as_source
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_target AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlinks_as_target
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    tag_metrics AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tags_used_in_excerpts
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ui.user_id,
    ui.reputation,
    ui.creationdate,
    ui.views,
    ui.upvotes,
    ui.downvotes,
    COALESCE(po.posts_owned, 0) AS posts_owned,
    COALESCE(po.total_post_score, 0) AS total_post_score,
    COALESCE(po.total_viewcount, 0) AS total_viewcount,
    COALESCE(po.avg_answer_count, 0) AS avg_answer_count,
    COALESCE(po.avg_comment_count, 0) AS avg_comment_count,
    COALESCE(po.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(pe.posts_edited, 0) AS posts_edited,
    COALESCE(cm.comments_made, 0) AS comments_made,
    COALESCE(cm.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(bm.badges_earned, 0) AS badges_earned,
    COALESCE(phm.post_history_entries, 0) AS post_history_entries,
    COALESCE(pls.postlinks_as_source, 0) AS postlinks_as_source,
    COALESCE(plt.postlinks_as_target, 0) AS postlinks_as_target,
    COALESCE(tm.tags_used_in_excerpts, 0) AS tags_used_in_excerpts
FROM user_info ui
LEFT JOIN post_owner po ON ui.user_id = po.user_id
LEFT JOIN post_editor pe ON ui.user_id = pe.user_id
LEFT JOIN comment_metrics cm ON ui.user_id = cm.user_id
LEFT JOIN vote_cast vc ON ui.user_id = vc.user_id
LEFT JOIN vote_received vr ON ui.user_id = vr.user_id
LEFT JOIN badge_metrics bm ON ui.user_id = bm.user_id
LEFT JOIN posthistory_metrics phm ON ui.user_id = phm.user_id
LEFT JOIN postlinks_source pls ON ui.user_id = pls.user_id
LEFT JOIN postlinks_target plt ON ui.user_id = plt.user_id
LEFT JOIN tag_metrics tm ON ui.user_id = tm.user_id
ORDER BY ui.reputation DESC
LIMIT 100
