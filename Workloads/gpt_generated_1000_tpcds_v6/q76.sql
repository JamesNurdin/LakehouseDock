/* goal: Compare total profit across catalog, store, and web channels by hour of day for California web sites during lunch hours, rank hours by combined profit, and filter to high‑profit periods */
WITH
    cs AS (
        SELECT
            cs_sold_time_sk,
            SUM(cs_net_profit)               AS cs_total_profit,
            SUM(cs_ext_sales_price)          AS cs_total_sales,
            COUNT(*)                         AS cs_txn_cnt
        FROM catalog_sales
        WHERE cs_net_paid_inc_ship > 500
          AND cs_order_number IN (8, 14, 15, 19, 20)
        GROUP BY cs_sold_time_sk
    ),
    ss AS (
        SELECT
            ss_sold_time_sk,
            SUM(ss_net_profit)               AS ss_total_profit,
            SUM(ss_ext_sales_price)          AS ss_total_sales,
            COUNT(*)                         AS ss_txn_cnt
        FROM store_sales
        WHERE ss_net_paid_inc_tax > 300
          AND ss_ext_discount_amt > 0
        GROUP BY ss_sold_time_sk
    ),
    ws AS (
        SELECT
            ws_sold_time_sk,
            ws_web_site_sk,
            SUM(ws_net_profit)               AS ws_total_profit,
            SUM(ws_ext_sales_price)          AS ws_total_sales,
            COUNT(*)                         AS ws_txn_cnt,
            SUM(ws_coupon_amt)               AS ws_total_coupons
        FROM web_sales
        WHERE ws_coupon_amt > 100
          AND ws_net_paid_inc_ship_tax BETWEEN 1000 AND 8000
        GROUP BY ws_sold_time_sk, ws_web_site_sk
    ),
    ws_site AS (
        SELECT
            ws.ws_sold_time_sk,
            ws.ws_web_site_sk,
            ws.ws_total_profit,
            ws.ws_total_sales,
            ws.ws_txn_cnt,
            ws.ws_total_coupons,
            web_site.web_name,
            web_site.web_state,
            web_site.web_gmt_offset
        FROM ws
        JOIN web_site
          ON ws.ws_web_site_sk = web_site.web_site_sk
        WHERE web_site.web_state = 'CA'
          AND web_site.web_gmt_offset BETWEEN -8.00 AND -5.00
    )
SELECT DISTINCT
    time_dim.t_hour,
    time_dim.t_meal_time,
    ws_site.web_name,
    cs.cs_total_profit,
    ss.ss_total_profit,
    ws_site.ws_total_profit,
    (cs.cs_total_profit + ss.ss_total_profit + ws_site.ws_total_profit) AS channel_total_profit,
    ROW_NUMBER() OVER (
        PARTITION BY time_dim.t_hour
        ORDER BY (cs.cs_total_profit + ss.ss_total_profit + ws_site.ws_total_profit) DESC
    )                                           AS profit_rank,
    DENSE_RANK() OVER (
        ORDER BY (cs.cs_total_profit + ss.ss_total_profit + ws_site.ws_total_profit) DESC
    )                                           AS overall_rank,
    CASE
        WHEN (cs.cs_total_profit + ss.ss_total_profit + ws_site.ws_total_profit) > 20000 THEN 'High'
        WHEN (cs.cs_total_profit + ss.ss_total_profit + ws_site.ws_total_profit) > 10000 THEN 'Medium'
        ELSE 'Low'
    END                                         AS profit_level
FROM time_dim
JOIN cs      ON cs.cs_sold_time_sk = time_dim.t_time_sk
JOIN ss      ON ss.ss_sold_time_sk = time_dim.t_time_sk
JOIN ws_site ON ws_site.ws_sold_time_sk = time_dim.t_time_sk
WHERE time_dim.t_hour BETWEEN 9 AND 17
  AND time_dim.t_meal_time = 'Lunch'
GROUP BY
    time_dim.t_hour,
    time_dim.t_meal_time,
    ws_site.web_name,
    cs.cs_total_profit,
    ss.ss_total_profit,
    ws_site.ws_total_profit,
    ws_site.web_state,
    ws_site.web_gmt_offset
HAVING SUM(cs.cs_total_profit + ss.ss_total_profit + ws_site.ws_total_profit) > 15000
ORDER BY overall_rank, time_dim.t_hour
LIMIT 100
