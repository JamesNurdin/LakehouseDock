WITH catalog_activity AS (
    SELECT
        d_s.d_date AS activity_date,
        s.s_store_id,
        cp.cp_department,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        COALESCE(SUM(cr.cr_return_amount), 0) AS web_sales_amount,
        SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit,
        RANK() OVER (PARTITION BY s.s_store_id ORDER BY SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN date_dim d_s ON cs.cs_sold_date_sk = d_s.d_date_sk
    JOIN time_dim t_s ON cs.cs_sold_time_sk = t_s.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN store s ON s.s_closed_date_sk = d_s.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d_s.d_date_sk
    WHERE d_s.d_year = 2001
      AND s.s_state = 'CA'
      AND cp.cp_department = 'Sports'
      AND t_s.t_meal_time = 'dinner'
      AND inv.inv_quantity_on_hand > 1000
    GROUP BY d_s.d_date, s.s_store_id, cp.cp_department
    HAVING SUM(cs.cs_ext_sales_price) > 10000
),
web_activity AS (
    SELECT
        d_w.d_date AS activity_date,
        NULL AS s_store_id,
        NULL AS cp_department,
        0.0 AS catalog_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS profit_rank
    FROM web_sales ws
    JOIN date_dim d_w ON ws.ws_sold_date_sk = d_w.d_date_sk
    JOIN time_dim t_w ON ws.ws_sold_time_sk = t_w.t_time_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE d_w.d_month_seq BETWEEN 1200 AND 1211
      AND r2.r_reason_desc LIKE '%customer%'
      AND t_w.t_meal_time = 'lunch'
    GROUP BY d_w.d_date
    HAVING SUM(ws.ws_ext_sales_price) > 5000
)
SELECT activity_date,
       s_store_id,
       cp_department,
       catalog_sales_amount,
       web_sales_amount,
       net_profit,
       profit_rank
FROM catalog_activity
UNION ALL
SELECT activity_date,
       s_store_id,
       cp_department,
       catalog_sales_amount,
       web_sales_amount,
       net_profit,
       profit_rank
FROM web_activity
ORDER BY activity_date ASC, profit_rank ASC
LIMIT 200
