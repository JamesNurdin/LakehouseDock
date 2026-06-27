WITH
    -- Aggregate posts per user (questions, answers, total, average score)
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_posts,
            COUNT(CASE WHEN p.posttypeid = 1 THEN 1 END) AS total_questions,
            COUNT(CASE WHEN p.posttypeid = 2 THEN 1 END) AS total_answers,
            AVG(p.score) AS avg_post_score
        FROM posts p
        GROUP BY p.owneruserid
    ),
    -- Comments that were made **on** a user's posts
    comments_on_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(c.id) AS total_comments_on_user_posts,
            AVG(c.score) AS avg_comment_score_on_user_posts
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Comments authored by the user
    comments_made AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS total_comments_made
        FROM comments c
        GROUP BY c.userid
    ),
    -- Votes received on a user's posts
    votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS total_votes_received,
            COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_received,
            COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Votes cast by the user
    votes_cast AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS total_votes_cast,
            COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvotes_cast,
            COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvotes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    -- Edits made by the user (posthistory entries)
    edits_made AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS total_edits_made
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    -- Links that originate from a user's posts
    links_from AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS total_links_from_user_posts
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    -- Links that point to a user's posts
    links_to AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(pl.id) AS total_links_to_user_posts
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    up.total_posts,
    up.total_questions,
    up.total_answers,
    up.avg_post_score,
    cp.total_comments_on_user_posts,
    cp.avg_comment_score_on_user_posts,
    cm.total_comments_made,
    vr.total_votes_received,
    vr.upvotes_received,
    vr.downvotes_received,
    vc.total_votes_cast,
    vc.upvotes_cast,
    vc.downvotes_cast,
    em.total_edits_made,
    lf.total_links_from_user_posts,
    lt.total_links_to_user_posts
FROM users u
LEFT JOIN user_posts up      ON u.id = up.user_id
LEFT JOIN comments_on_posts cp ON u.id = cp.user_id
LEFT JOIN comments_made cm   ON u.id = cm.user_id
LEFT JOIN votes_received vr ON u.id = vr.user_id
LEFT JOIN votes_cast vc     ON u.id = vc.user_id
LEFT JOIN edits_made em     ON u.id = em.user_id
LEFT JOIN links_from lf     ON u.id = lf.user_id
LEFT JOIN links_to lt       ON u.id = lt.user_id
ORDER BY up.total_posts DESC NULLS LAST
LIMIT 100
