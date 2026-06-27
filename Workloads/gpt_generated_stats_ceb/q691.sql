WITH
    user_base AS (
        SELECT
            id AS user_id,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    ),
    post_stats AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            COALESCE(SUM(score), 0) AS total_post_score,
            COALESCE(SUM(viewcount), 0) AS total_post_views,
            COALESCE(SUM(answercount), 0) AS total_answer_count,
            COALESCE(SUM(commentcount), 0) AS total_comment_count,
            COALESCE(SUM(favoritecount), 0) AS total_favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    edit_stats AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS total_edited_posts
        FROM posts
        GROUP BY lasteditoruserid
    ),
    comment_stats AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments,
            COALESCE(SUM(score), 0) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    vote_stats AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_votes_cast,
            COALESCE(SUM(votetypeid), 0) AS total_vote_type_sum
        FROM votes
        GROUP BY userid
    ),
    badge_stats AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ),
    postlink_stats AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_postlinks
        FROM postlinks pl
        JOIN posts p
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    tag_stats AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_tags
        FROM tags t
        JOIN posts p
            ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_stats AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_posthistory
        FROM posthistory
        GROUP BY userid
    )
SELECT
    ub.user_id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(ps.total_posts, 0) AS total_posts,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    CASE WHEN COALESCE(ps.total_posts, 0) = 0 THEN 0
         ELSE COALESCE(ps.total_post_score, 0) / COALESCE(ps.total_posts, 1)
    END AS avg_post_score,
    COALESCE(ps.total_post_views, 0) AS total_post_views,
    COALESCE(ps.total_answer_count, 0) AS total_answer_count,
    COALESCE(ps.total_comment_count, 0) AS total_comment_count,
    COALESCE(ps.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(es.total_edited_posts, 0) AS total_edited_posts,
    COALESCE(cs.total_comments, 0) AS total_comments,
    COALESCE(cs.total_comment_score, 0) AS total_comment_score,
    COALESCE(vs.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vs.total_vote_type_sum, 0) AS total_vote_type_sum,
    COALESCE(bs.total_badges, 0) AS total_badges,
    COALESCE(pls.total_postlinks, 0) AS total_postlinks,
    COALESCE(tgs.total_tags, 0) AS total_tags,
    COALESCE(phs.total_posthistory, 0) AS total_posthistory
FROM user_base ub
LEFT JOIN post_stats ps
    ON ub.user_id = ps.user_id
LEFT JOIN edit_stats es
    ON ub.user_id = es.user_id
LEFT JOIN comment_stats cs
    ON ub.user_id = cs.user_id
LEFT JOIN vote_stats vs
    ON ub.user_id = vs.user_id
LEFT JOIN badge_stats bs
    ON ub.user_id = bs.user_id
LEFT JOIN postlink_stats pls
    ON ub.user_id = pls.user_id
LEFT JOIN tag_stats tgs
    ON ub.user_id = tgs.user_id
LEFT JOIN posthistory_stats phs
    ON ub.user_id = phs.user_id
ORDER BY total_posts DESC
LIMIT 20
