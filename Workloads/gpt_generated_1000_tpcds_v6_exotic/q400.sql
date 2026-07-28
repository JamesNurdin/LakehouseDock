/*
Goal: Rank stores (in California, year 2001, selling Sports items during business hours) by their net profit, compare each store's daily profit to its overall average profit, and flag high‑profit days. The query joins all 11 TPC‑DS tables using only the permitted keys, applies five filter predicates, uses a CASE expression, a correlated scalar sub‑query, and a window RANK function, then orders the results and limits to the top 100 rows.
*/
WITH base AS (
    SELECT
        s.s_store_id,
        s.s_state,
        s.s_gmt_offset,
        s.s_store_sk,
        d_sales.d_date,
        d_sales.d_year,
        i.i_category,
        i.i_brand,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_net_paid_inc_tax,
        sr.sr_net_loss,
        cs.cs_net_profit      AS catalog_net_profit,
        cr.cr_net_loss        AS catalog_return_loss,
        wr.wr_net_loss        AS web_return_loss,
        p.p_promo_name,
        p.p_discount_active,
        ws.web_name,
        ws.web_gmt_offset,
        t_sales.t_hour,
        ss.ss_store_sk
    FROM store_sales ss
    JOIN date_dim d_sales
      ON ss.ss_sold_date_sk = d_sales.d_date_sk                -- store_sales → date_dim
    JOIN time_dim t_sales
      ON ss.ss_sold_time_sk = t_sales.t_time_sk                -- store_sales → time_dim
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk                            -- store_sales → item
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk                           -- store_sales → store
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk                           -- store_sales → promotion
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk                           -- store_returns → store_sales & item
    LEFT JOIN catalog_sales cs
      ON cs.cs_order_number = ss.ss_ticket_number
     AND cs.cs_item_sk = ss.ss_item_sk                            -- catalog_sales → store_sales (via ticket & item)
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk                            -- catalog_returns → catalog_sales
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = ss.ss_item_sk                            -- web_returns → item (and indirectly to store_sales)
    LEFT JOIN web_site ws
      ON ws.web_open_date_sk = d_sales.d_date_sk                 -- web_site → date_dim (open date)
    LEFT JOIN date_dim d_store_closed
      ON s.s_closed_date_sk = d_store_closed.d_date_sk          -- store → date_dim (closed date)
    LEFT JOIN date_dim d_p_start
      ON p.p_start_date_sk = d_p_start.d_date_sk                -- promotion → date_dim (start)
    LEFT JOIN date_dim d_p_end
      ON p.p_end_date_sk = d_p_end.d_date_sk                    -- promotion → date_dim (end)
    LEFT JOIN item i_p
      ON p.p_item_sk = i_p.i_item_sk                            -- promotion → item (promo item)
    WHERE d_sales.d_year = 2001                                   -- predicate 1
      AND i.i_category = 'Sports'                                 -- predicate 2
      AND s.s_state = 'CA'                                        -- predicate 3
      AND p.p_discount_active = 'Y'                               -- predicate 4
      AND t_sales.t_hour BETWEEN 9 AND 17                         -- predicate 5
      AND s.s_gmt_offset = -6.00                                 -- predicate 6
),
augmented AS (
    SELECT
        *,
        CASE WHEN ss_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        RANK() OVER (PARTITION BY d_year ORDER BY ss_net_profit DESC) AS yearly_store_rank,
        (
            SELECT AVG(ss2.ss_net_profit)
            FROM store_sales ss2
            WHERE ss2.ss_store_sk = base.ss_store_sk
        ) AS avg_store_profit
    FROM base
)
SELECT
    s_store_id,
    d_date,
    i_category,
    SUM(ss_net_profit)                     AS total_store_profit,
    SUM(ss_net_paid_inc_tax)               AS total_sales_amount,
    SUM(sr_net_loss)                       AS total_store_return_loss,
    SUM(catalog_net_profit)                AS total_catalog_profit,
    SUM(catalog_return_loss)               AS total_catalog_return_loss,
    SUM(web_return_loss)                   AS total_web_return_loss,
    profit_category,
    yearly_store_rank,
    avg_store_profit,
    CASE WHEN SUM(ss_net_profit) > avg_store_profit THEN 'Above Avg' ELSE 'Below Avg' END AS profit_vs_average
FROM augmented
GROUP BY
    s_store_id,
    d_date,
    i_category,
    profit_category,
    yearly_store_rank,
    avg_store_profit
ORDER BY total_store_profit DESC
LIMIT 100
