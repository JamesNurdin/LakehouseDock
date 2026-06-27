WITH post_metrics AS (
    SELECT
        date_trunc('month', creationdate) AS month,
        COUNT(*) AS posts_cnt,
        SUM(score) AS posts_score_sum,
        AVG(viewcount) AS posts_view_avg,
        COUNT(DISTINCT owneruserid) AS distinct_owners,
        SUM(answercount) AS total_answers,
        SUM(commentcount) AS total_comments
    FROM posts
    GROUP BY date_trunc('month', creationdate)
),
comment_metrics AS (
    SELECT
        date_trunc('month', creationdate) AS month,
        COUNT(*) AS comments_cnt,
        SUM(score) AS comments_score_sum,
        COUNT(DISTINCT userid) AS distinct_commenters
    FROM comments
    GROUP BY date_trunc('month', creationdate)
),
vote_metrics AS (
    SELECT
        date_trunc('month', creationdate) AS month,
        COUNT(*) AS votes_cnt,
        COUNT(DISTINCT userid) AS distinct_voters
    FROM votes
    GROUP BY date_trunc('month', creationdate)
),
badge_metrics AS (
    SELECT
        date_trunc('month', date) AS month,
        COUNT(*) AS badges_cnt,
        COUNT(DISTINCT userid) AS distinct_badge_earners
    FROM badges
    GROUP BY date_trunc('month', date)
),
user_metrics AS (
    SELECT
        date_trunc('month', creationdate) AS month,
        COUNT(*) AS new_users,
        SUM(reputation) AS total_reputation,
        AVG(reputation) AS avg_reputation
    FROM users
    GROUP BY date_trunc('month', creationdate)
),
tag_metrics AS (
    SELECT
        date_trunc('month', p.creationdate) AS month,
        COUNT(DISTINCT t.id) AS distinct_tags,
        SUM(t.count) AS total_tag_uses
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY date_trunc('month', p.creationdate)
),
postlink_metrics AS (
    SELECT
        date_trunc('month', creationdate) AS month,
        COUNT(*) AS postlinks_cnt,
        COUNT(DISTINCT linktypeid) AS distinct_link_types
    FROM postlinks
    GROUP BY date_trunc('month', creationdate)
),
posthistory_metrics AS (
    SELECT
        date_trunc('month', creationdate) AS month,
        COUNT(*) AS posthistory_cnt,
        COUNT(DISTINCT userid) AS distinct_editors
    FROM posthistory
    GROUP BY date_trunc('month', creationdate)
)
SELECT
    pm.month,
    pm.posts_cnt,
    pm.posts_score_sum,
    pm.posts_view_avg,
    pm.distinct_owners,
    pm.total_answers,
    pm.total_comments,
    cm.comments_cnt,
    cm.comments_score_sum,
    cm.distinct_commenters,
    vm.votes_cnt,
    vm.distinct_voters,
    bm.badges_cnt,
    bm.distinct_badge_earners,
    um.new_users,
    um.total_reputation,
    um.avg_reputation,
    tm.distinct_tags,
    tm.total_tag_uses,
    plm.postlinks_cnt,
    plm.distinct_link_types,
    phm.posthistory_cnt,
    phm.distinct_editors
FROM post_metrics pm
LEFT JOIN comment_metrics cm ON pm.month = cm.month
LEFT JOIN vote_metrics vm ON pm.month = vm.month
LEFT JOIN badge_metrics bm ON pm.month = bm.month
LEFT JOIN user_metrics um ON pm.month = um.month
LEFT JOIN tag_metrics tm ON pm.month = tm.month
LEFT JOIN postlink_metrics plm ON pm.month = plm.month
LEFT JOIN posthistory_metrics phm ON pm.month = phm.month
ORDER BY pm.month
