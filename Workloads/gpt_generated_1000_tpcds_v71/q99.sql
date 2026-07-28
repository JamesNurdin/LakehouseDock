/*
  Goal: Analyze the combined financial impact of promotions and return reasons across store sales, store returns, catalog sales and web returns. The query joins all eight selected tables using only the permitted join keys, aggregates per promotion and return‑reason, filters heavily, applies a scalar subquery, uses window functions, and returns the top contributors.
*/
WITH joined AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_promo_sk,
        p.p_promo_name,
        p.p_channel_event,
        p.p_channel_demo,
        sr.sr_reason_sk,
        r.r_reason_desc,
        cs.cs_order_number,
        cs.cs_quantity,
        wr.wr_order_number,
        wr.wr_reason_sk AS wr_reason_sk,
        t.t_hour,
        ss.ss_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss,
        (ss.ss_net_profit - COALESCE(sr.sr_net_loss, 0) - COALESCE(wr.wr_net_loss, 0)) AS net_contribution
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN web_returns wr
        ON ss.ss_ticket_number = wr.wr_order_number
        AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        p.p_channel_event = 'N'                     -- 1st predicate
        AND p.p_channel_demo = 'N'                 -- 2nd predicate
        AND t.t_hour BETWEEN 9 AND 17              -- 3rd predicate (business hours)
        AND ss.ss_net_profit < 0                   -- 4th predicate (losses)
        AND sr.sr_return_quantity > 0              -- 5th predicate (has return)
        AND wr.wr_return_quantity > 0              -- 6th predicate (has web return)
        AND cs.cs_quantity > 0                     -- 7th predicate (catalog sale qty)
),
agg AS (
    SELECT
        p_promo_name,
        r_reason_desc,
        SUM(ss_net_profit)          AS total_store_profit,
        SUM(sr_net_loss)            AS total_store_loss,
        SUM(wr_net_loss)            AS total_web_loss,
        SUM(net_contribution)       AS total_contrib,
        COUNT(*)                    AS transaction_cnt
    FROM joined
    GROUP BY p_promo_name, r_reason_desc
    HAVING COUNT(*) >= 10                         -- only groups with enough activity
)
SELECT
    p_promo_name,
    r_reason_desc,
    total_store_profit,
    total_store_loss,
    total_web_loss,
    total_contrib,
    transaction_cnt,
    RANK() OVER (ORDER BY total_contrib DESC)               AS contrib_rank,
    (total_contrib / NULLIF(SUM(total_contrib) OVER (), 0)) * 100 AS contrib_pct
FROM agg
WHERE total_contrib > (
    SELECT AVG(total_contrib) FROM agg               -- scalar subquery filter
)
ORDER BY total_contrib DESC
LIMIT 100
