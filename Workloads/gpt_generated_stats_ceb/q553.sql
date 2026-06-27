WITH
    -- Posts owned by each user and their basic aggregates
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_viewcount,
            SUM(answercount) AS total_answers,
            SUM(commentcount) AS total_comments_received,
            SUM(favoritecount) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    -- Votes that landed on a user’s posts
    user_votes AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS total_votes_on_posts
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Comments authored by each user (regardless of which post they belong to)
    user_comments_made AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments_made
        FROM comments
        GROUP BY userid
    ),
    -- Badges earned by each user
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ),
    -- All post‑history events performed by a user (e.g., edits, closures)
    user_posthistory_by_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_posthistory_events_by_user
        FROM posthistory
        GROUP BY userid
    ),
    -- Post‑history events that happened on a user’s own posts (joined via the allowed rule)
    user_posthistory_on_owned_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(ph.id) AS total_posthistory_events_on_owned_posts
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    -- Posts edited by a user (last editor)
    user_posts_edited AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS total_posts_edited
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    -- Tag excerpts that point to a user’s posts
    user_tag_excerpts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(t.id) AS total_tag_excerpts
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    -- Post‑links where the user’s post is the source
    user_postlinks AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS total_postlinks
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Post‑links where the user’s post is the target (relatedpostid)
    user_related_postlinks AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS total_related_postlinks
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation AS user_reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments_received, 0) AS total_comments_received,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uv.total_votes_on_posts, 0) AS total_votes_on_posts,
    COALESCE(uc.total_comments_made, 0) AS total_comments_made,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(upb.total_posthistory_events_by_user, 0) AS total_posthistory_events_by_user,
    COALESCE(upon.total_posthistory_events_on_owned_posts, 0) AS total_posthistory_events_on_owned_posts,
    COALESCE(ue.total_posts_edited, 0) AS total_posts_edited,
    COALESCE(ut.total_tag_excerpts, 0) AS total_tag_excerpts,
    COALESCE(pl.total_postlinks, 0) AS total_postlinks,
    COALESCE(rpl.total_related_postlinks, 0) AS total_related_postlinks,
    -- Example derived metric: average score of a user’s posts
    CASE WHEN COALESCE(up.total_posts, 0) = 0 THEN 0
         ELSE COALESCE(up.total_post_score, 0) / CAST(COALESCE(up.total_posts, 1) AS DOUBLE)
    END AS avg_post_score
FROM users u
LEFT JOIN user_posts up       ON up.user_id = u.id
LEFT JOIN user_votes uv       ON uv.user_id = u.id
LEFT JOIN user_comments_made uc ON uc.user_id = u.id
LEFT JOIN user_badges ub      ON ub.user_id = u.id
LEFT JOIN user_posthistory_by_user upb ON upb.user_id = u.id
LEFT JOIN user_posthistory_on_owned_posts upon ON upon.user_id = u.id
LEFT JOIN user_posts_edited ue ON ue.user_id = u.id
LEFT JOIN user_tag_excerpts ut ON ut.user_id = u.id
LEFT JOIN user_postlinks pl   ON pl.user_id = u.id
LEFT JOIN user_related_postlinks rpl ON rpl.user_id = u.id
ORDER BY total_posts DESC, total_post_score DESC
LIMIT 100
