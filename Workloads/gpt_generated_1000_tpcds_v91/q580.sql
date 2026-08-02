WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_sold_time_sk,
        ss.ss_promo_sk,
        p_store.p_promo_id               AS promo_id,
        p_store.p_channel_email,
        p_store.p_channel_tv,
        t_sales.t_hour                    AS sale_hour,
        t_sales.t_time_sk                 AS sale_time_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        ws.ws_quantity                    AS web_quantity,
        ws.ws_net_paid                    AS web_net_paid,
        ws.ws_sold_time_sk,
        t_web.t_hour                      AS web_sale_hour,
        p_web.p_promo_id                  AS web_promo_id,
        p_web.p_channel_email             AS web_channel_email
    FROM store_sales ss
    -- Promotion joined twice under different aliases (different roles)
    JOIN promotion p_store
        ON ss.ss_promo_sk = p_store.p_promo_sk
    JOIN promotion p_web
        ON ss.ss_promo_sk = p_web.p_promo_sk
    -- Time dimension joined multiple times for store_sales
    JOIN time_dim t_sales
        ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN time_dim t_sales_dup
        ON ss.ss_sold_time_sk = t_sales_dup.t_time_sk
    -- Store returns linked by item and by ticket (two distinct joins to store_sales)
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
    JOIN store_sales ss2
        ON sr.sr_ticket_number = ss2.ss_ticket_number
    -- Time dimension joined multiple times for store_returns
    JOIN time_dim t_return
        ON sr.sr_return_time_sk = t_return.t_time_sk
    JOIN time_dim t_return_dup
        ON sr.sr_return_time_sk = t_return_dup.t_time_sk
    -- Web sales joined twice to promotion and time dimension
    JOIN web_sales ws
        ON ws.ws_promo_sk = p_web.p_promo_sk
    JOIN time_dim t_web
        ON ws.ws_sold_time_sk = t_web.t_time_sk
    JOIN time_dim t_web_dup
        ON ws.ws_sold_time_sk = t_web_dup.t_time_sk
    -- Correlated subquery in WHERE clause (exists matching web sale for same promo & time)
    WHERE EXISTS (
        SELECT 1 FROM web_sales ws_corr
        WHERE ws_corr.ws_promo_sk = ss.ss_promo_sk
          AND ws_corr.ws_sold_time_sk = ss.ss_sold_time_sk
    )
      -- Set subtraction with EXCEPT to keep only promotions that are active but not inactive
      AND p_store.p_promo_id IN (
          SELECT p.p_promo_id FROM promotion p WHERE p.p_discount_active = 'Y'
          EXCEPT
          SELECT p.p_promo_id FROM promotion p WHERE p.p_discount_active = 'N'
      )
)
SELECT
    jd.p_channel_email,
    jd.sale_hour,
    SUM(jd.ss_net_profit)               AS total_net_profit,
    SUM(jd.ss_quantity)                 AS total_quantity,
    COUNT(DISTINCT jd.ss_ticket_number) AS distinct_tickets,
    CASE WHEN SUM(jd.ss_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category,
    (
        SELECT COUNT(*)
        FROM store_returns sr_sub
        JOIN time_dim td_sub ON sr_sub.sr_return_time_sk = td_sub.t_time_sk
        WHERE td_sub.t_hour = jd.sale_hour
    )                                   AS returns_in_same_hour
FROM joined_data jd
GROUP BY ROLLUP (jd.p_channel_email, jd.sale_hour)
ORDER BY total_net_profit DESC
LIMIT 100
