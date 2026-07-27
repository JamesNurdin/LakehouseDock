/* goal: Identify top catalog sales orders for the year 2001, enriched with date, time, shipping, warehouse, store sales, web returns and website information, applying profit classification, multiple filters, window rankings, moving aggregates and an existence check. */
WITH cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS cs_profit_flag
    FROM catalog_sales cs
)
SELECT
    cs.cs_order_number,
    d.d_date,
    d.d_year,
    t.t_hour,
    sm.sm_type,
    w.w_warehouse_name,
    w.w_state,
    ss.ss_net_paid AS store_net_paid,
    wr.wr_return_amt,
    ws.web_name,
    cs.cs_profit_flag,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cs.cs_net_paid DESC) AS rn_year,
    RANK() OVER (ORDER BY cs.cs_net_paid DESC) AS overall_rank,
    SUM(cs.cs_net_paid) OVER (
        PARTITION BY sm.sm_type
        ORDER BY d.d_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_7day_sum
FROM cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_sales ss
    ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
   AND ss.ss_sold_time_sk = cs.cs_sold_time_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = cs.cs_sold_date_sk
   AND wr.wr_returned_time_sk = cs.cs_sold_time_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND t.t_hour BETWEEN 8 AND 17
  AND sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
  AND w.w_state = 'CA'
  AND cs.cs_net_paid > 0
  AND EXISTS (
        SELECT 1
        FROM store_sales s2
        WHERE s2.ss_sold_date_sk = cs.cs_sold_date_sk
          AND s2.ss_net_paid > 1000
    )
ORDER BY cs.cs_net_paid DESC
LIMIT 100
