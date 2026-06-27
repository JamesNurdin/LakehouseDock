/*
  User activity summary – aggregates per user across posts, comments, votes, badges, edits, and tags.
  Shows the top 100 users by reputation.
*/
WITH user_base AS (
    SELECT
        u.id AS userid,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
),
post_stats AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers_count,
        SUM(p.commentcount) AS total_comments_on_posts,
        SUM(p.favoritecount) AS total_favorites
    FROM posts p
    GROUP BY p.owneruserid
),
answer_stats AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS answer_count
    FROM posts p
    WHERE p.posttypeid = 2
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT
        c.userid,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
vote_cast_stats AS (
    SELECT
        v.userid,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS total_bounty_cast
    FROM votes v
    GROUP BY v.userid
),
badge_stats AS (
    SELECT
        b.userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
edit_stats AS (
    SELECT
        ph.userid,
        COUNT(*) AS edit_count
    FROM posthistory ph
    GROUP BY ph.userid
),
last_edit_stats AS (
    SELECT
        p.lasteditoruserid AS userid,
        COUNT(*) AS last_edit_count
    FROM posts p
    GROUP BY p.lasteditoruserid
),
bounty_received_stats AS (
    SELECT
        p.owneruserid AS userid,
        SUM(v.bountyamount) AS total_bounty_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    WHERE v.bountyamount IS NOT NULL
    GROUP BY p.owneruserid
),
tag_stats AS (
    SELECT
        p.owneruserid AS userid,
        SUM(t.count) AS total_tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.userid,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(ps.post_count, 0)               AS post_count,
    COALESCE(ps.total_post_score, 0)          AS total_post_score,
    COALESCE(ps.avg_post_score, 0)            AS avg_post_score,
    COALESCE(ps.total_views, 0)               AS total_views,
    COALESCE(ps.total_answers_count, 0)      AS total_answers_on_posts,
    COALESCE(ps.total_comments_on_posts, 0)  AS total_comments_on_posts,
    COALESCE(ps.total_favorites, 0)           AS total_favorites,
    COALESCE(asw.answer_count, 0)             AS answer_count,
    COALESCE(cs.comment_count, 0)             AS comment_count,
    COALESCE(vcs.votes_cast, 0)               AS votes_cast,
    COALESCE(vcs.total_bounty_cast, 0)        AS total_bounty_cast,
    COALESCE(bs.badge_count, 0)               AS badge_count,
    COALESCE(es.edit_count, 0)                AS edit_count,
    COALESCE(les.last_edit_count, 0)          AS last_edit_count,
    COALESCE(brs.total_bounty_received, 0)    AS total_bounty_received,
    COALESCE(ts.total_tag_count, 0)           AS total_tag_count
FROM user_base u
LEFT JOIN post_stats ps           ON ps.userid = u.userid
LEFT JOIN answer_stats asw        ON asw.userid = u.userid
LEFT JOIN comment_stats cs        ON cs.userid = u.userid
LEFT JOIN vote_cast_stats vcs     ON vcs.userid = u.userid
LEFT JOIN badge_stats bs          ON bs.userid = u.userid
LEFT JOIN edit_stats es           ON es.userid = u.userid
LEFT JOIN last_edit_stats les     ON les.userid = u.userid
LEFT JOIN bounty_received_stats brs ON brs.userid = u.userid
LEFT JOIN tag_stats ts            ON ts.userid = u.userid
ORDER BY u.reputation DESC
LIMIT 100
