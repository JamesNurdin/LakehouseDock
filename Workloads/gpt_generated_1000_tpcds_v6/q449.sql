WITH ss_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_sold_time_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price)            AS total_sales,
        SUM(ss.ss_quantity)                   AS total_qty,
        COUNT(*)                               AS sales_cnt
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451175               -- filter 1 (date surrogate range)
      AND ss.ss_ext_sales_price > 0                                 -- filter 2 (positive sales amount)
    GROUP BY
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_sold_time_sk,
        ss.ss_sold_date_sk
    HAVING SUM(ss.ss_ext_sales_price) > 1000                         -- filter 3 (aggregate threshold)
)
SELECT
    DISTINCT
    s.s_store_id,
    i.i_item_id,
    cd.cd_gender,
    r_s.r_reason_desc,
    t_ss.t_hour,
    CASE
        WHEN ss_agg.total_sales >= 5000 THEN 'High'
        WHEN ss_agg.total_sales >= 2000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    COUNT(DISTINCT sr.sr_ticket_number) OVER (
        PARTITION BY s.s_store_id
        ORDER BY ss_agg.total_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_tickets,
    RANK() OVER (PARTITION BY s.s_store_id ORDER BY ss_agg.total_sales DESC) AS sales_rank,
    ss_agg.total_sales,
    ss_agg.total_qty
FROM ss_agg
JOIN item i
    ON ss_agg.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss_agg.ss_store_sk = s.s_store_sk
JOIN customer c
    ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN time_dim t_ss
    ON ss_agg.ss_sold_time_sk = t_ss.t_time_sk
/* Store return relationship via ticket number */
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_store_sk = s.s_store_sk
   AND EXISTS (
        SELECT 1
        FROM store_sales ss_check
        WHERE ss_check.ss_ticket_number = sr.sr_ticket_number
          AND ss_check.ss_item_sk = i.i_item_sk
          AND ss_check.ss_store_sk = s.s_store_sk
   )
JOIN reason r_s
    ON sr.sr_reason_sk = r_s.r_reason_sk
/* Web return side */
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND EXISTS (
        SELECT 1
        FROM store_sales ss_check2
        WHERE ss_check2.ss_ticket_number = wr.wr_order_number
    )
JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r_w
    ON wr.wr_reason_sk = r_w.r_reason_sk
JOIN customer c_ref
    ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
WHERE s.s_state = 'CA'                         -- predicate 4 (store location)
  AND i.i_current_price BETWEEN 10 AND 100    -- predicate 5 (item price range)
  AND t_ss.t_hour BETWEEN 9 AND 17            -- predicate 6 (business hours)
ORDER BY sales_rank, ss_agg.total_sales DESC
LIMIT 100
