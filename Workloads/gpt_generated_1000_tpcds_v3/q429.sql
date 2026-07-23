WITH cs_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_profit) AS cs_total_profit,
        SUM(cs.cs_quantity) AS cs_total_quantity,
        COUNT(*) AS cs_sales_cnt,
        SUM(CASE WHEN cp.cp_department = 'Electronics' THEN cs.cs_net_profit ELSE 0 END) AS cs_elec_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    WHERE d_sold.d_year = 2001
      AND t_sold.t_meal_time = 'dinner'
      AND sm.sm_type = 'AIR'
      AND cd_bill.cd_gender = 'M'
      AND cp.cp_department = 'Electronics'
    GROUP BY cs.cs_bill_customer_sk
),
ws_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_profit) AS ws_total_profit,
        SUM(ws.ws_quantity) AS ws_total_quantity,
        COUNT(*) AS ws_sales_cnt
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    WHERE d_ws_sold.d_year = 2001
      AND t_ws_sold.t_meal_time = 'dinner'
      AND sm_ws.sm_type = 'AIR'
      AND wsite.web_country = 'United States'
    GROUP BY ws.ws_bill_customer_sk
),
sr_agg AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_net_loss) AS sr_total_loss,
        COUNT(*) AS sr_return_cnt,
        SUM(CASE WHEN r.r_reason_desc = 'Damaged' THEN sr.sr_return_amt ELSE 0 END) AS sr_damaged_loss
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d_sr_ret ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
    JOIN time_dim t_sr_ret ON sr.sr_return_time_sk = t_sr_ret.t_time_sk
    WHERE d_sr_ret.d_year = 2001
      AND t_sr_ret.t_meal_time = 'dinner'
      AND sr.sr_return_quantity > 0
    GROUP BY sr.sr_customer_sk
)
SELECT
    c.c_customer_id,
    COALESCE(cs.cs_total_profit, 0) AS catalog_total_profit,
    COALESCE(ws.ws_total_profit, 0) AS web_total_profit,
    COALESCE(sr.sr_total_loss, 0) AS total_return_loss,
    (COALESCE(cs.cs_total_profit, 0) + COALESCE(ws.ws_total_profit, 0) - COALESCE(sr.sr_total_loss, 0)) AS net_total_profit,
    CASE
        WHEN (COALESCE(cs.cs_total_profit, 0) + COALESCE(ws.ws_total_profit, 0) - COALESCE(sr.sr_total_loss, 0)) > 5000 THEN 'High'
        WHEN (COALESCE(cs.cs_total_profit, 0) + COALESCE(ws.ws_total_profit, 0) - COALESCE(sr.sr_total_loss, 0)) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (
        ORDER BY (COALESCE(cs.cs_total_profit, 0) + COALESCE(ws.ws_total_profit, 0) - COALESCE(sr.sr_total_loss, 0)) DESC
    ) AS profit_rank,
    cs.cs_sales_cnt,
    ws.ws_sales_cnt,
    sr.sr_return_cnt
FROM customer c
LEFT JOIN cs_agg cs ON c.c_customer_sk = cs.customer_sk
LEFT JOIN ws_agg ws ON c.c_customer_sk = ws.customer_sk
LEFT JOIN sr_agg sr ON c.c_customer_sk = sr.customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
ORDER BY net_total_profit DESC
LIMIT 100
