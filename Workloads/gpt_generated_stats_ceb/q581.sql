/*
  Analytical overview of Stack‑Exchange posts by post type.
  The query aggregates core metrics from the five allowed tables:
  posts, comments, votes, postlinks and tags.
  It uses only the permitted join relationships and respects all
  Trino‑SQL and modelling rules.
*/
WITH posts_agg AS (
    SELECT
        posttypeid,
        COUNT(*) AS num_posts,
        SUM(score) AS sum_post_score,
        SUM(viewcount) AS sum_viewcount,
        SUM(answercount) AS sum_answercount,
        SUM(commentcount) AS sum_commentcount,
        SUM(favoritecount) AS sum_favoritecount
    FROM posts
    GROUP BY posttypeid
),
comments_agg AS (
    SELECT
        p.posttypeid,
        COUNT(c.id) AS comment_cnt,
        SUM(c.score) AS comment_score_sum
    FROM posts p
    JOIN comments c ON c.postid = p.id
    GROUP BY p.posttypeid
),
votes_agg AS (
    SELECT
        p.posttypeid,
        COUNT(v.id) AS vote_cnt,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cnt,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS closevote_cnt,
        SUM(CASE WHEN v.votetypeid = 4 THEN 1 ELSE 0 END) AS deletevote_cnt,
        SUM(CASE WHEN v.votetypeid = 5 THEN 1 ELSE 0 END) AS undeletevote_cnt,
        SUM(CASE WHEN v.votetypeid = 6 THEN 1 ELSE 0 END) AS spamvote_cnt,
        SUM(CASE WHEN v.votetypeid = 7 THEN 1 ELSE 0 END) AS offervote_cnt,
        SUM(CASE WHEN v.votetypeid = 8 THEN 1 ELSE 0 END) AS bountyvote_cnt,
        SUM(CASE WHEN v.votetypeid = 9 THEN 1 ELSE 0 END) AS moderatorvote_cnt,
        SUM(CASE WHEN v.votetypeid = 10 THEN 1 ELSE 0 END) AS reviewvote_cnt,
        SUM(v.bountyamount) AS sum_bounty_amount
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.posttypeid
),
postlinks_out_agg AS (
    SELECT
        p.posttypeid,
        COUNT(pl.id) AS outgoing_link_cnt,
        COUNT(DISTINCT pl.relatedpostid) AS distinct_outgoing_target_cnt
    FROM posts p
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.posttypeid
),
postlinks_in_agg AS (
    SELECT
        p.posttypeid,
        COUNT(pl.id) AS incoming_link_cnt,
        COUNT(DISTINCT pl.postid) AS distinct_incoming_source_cnt
    FROM posts p
    JOIN postlinks pl ON pl.relatedpostid = p.id
    GROUP BY p.posttypeid
),
tags_agg AS (
    SELECT
        p.posttypeid,
        COUNT(t.id) AS tag_cnt,
        SUM(t."count") AS sum_tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.posttypeid
)
SELECT
    pa.posttypeid,
    pa.num_posts,
    pa.sum_post_score,
    pa.sum_post_score / NULLIF(pa.num_posts, 0) AS avg_post_score,
    pa.sum_viewcount,
    pa.sum_viewcount / NULLIF(pa.num_posts, 0) AS avg_viewcount,
    pa.sum_answercount,
    pa.sum_answercount / NULLIF(pa.num_posts, 0) AS avg_answercount,
    pa.sum_commentcount,
    pa.sum_commentcount / NULLIF(pa.num_posts, 0) AS avg_commentcount,
    pa.sum_favoritecount,
    pa.sum_favoritecount / NULLIF(pa.num_posts, 0) AS avg_favoritecount,
    COALESCE(ca.comment_cnt, 0) AS total_comments,
    COALESCE(ca.comment_cnt, 0) / NULLIF(pa.num_posts, 0) AS avg_comments_per_post,
    COALESCE(ca.comment_score_sum, 0) AS total_comment_score,
    COALESCE(ca.comment_score_sum, 0) / NULLIF(COALESCE(ca.comment_cnt, 0), 0) AS avg_comment_score,
    COALESCE(va.vote_cnt, 0) AS total_votes,
    COALESCE(va.vote_cnt, 0) / NULLIF(pa.num_posts, 0) AS avg_votes_per_post,
    COALESCE(va.upvote_cnt, 0) AS upvote_cnt,
    COALESCE(va.downvote_cnt, 0) AS downvote_cnt,
    COALESCE(va.sum_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(po.outgoing_link_cnt, 0) AS outgoing_links,
    COALESCE(pi.incoming_link_cnt, 0) AS incoming_links,
    COALESCE(tg.tag_cnt, 0) AS tags_excerpts,
    COALESCE(tg.sum_tag_count, 0) AS sum_tag_counts
FROM posts_agg pa
LEFT JOIN comments_agg ca ON ca.posttypeid = pa.posttypeid
LEFT JOIN votes_agg va ON va.posttypeid = pa.posttypeid
LEFT JOIN postlinks_out_agg po ON po.posttypeid = pa.posttypeid
LEFT JOIN postlinks_in_agg pi ON pi.posttypeid = pa.posttypeid
LEFT JOIN tags_agg tg ON tg.posttypeid = pa.posttypeid
ORDER BY avg_post_score DESC
LIMIT 10
