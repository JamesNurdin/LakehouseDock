WITH sales_with_date AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_cdemo_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450810 AND 2450820
      AND ws.ws_quantity > 5
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    ws.ws_web_page_sk,
    CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
    SUM(ws.ws_quantity)                           AS total_quantity,
    AVG(ws.ws_ext_sales_price)                    AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number)            AS order_cnt,
    MIN(ws.ws_net_profit)                         AS min_profit,
    MAX(ws.ws_net_profit)                         AS max_profit,
    SUM(CASE WHEN r.r_reason_desc = 'Damaged' THEN ws.ws_ext_sales_price ELSE 0 END) AS damaged_sales
FROM sales_with_date ws
JOIN date_dim d        ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t        ON ws.ws_sold_time_sk = t.t_time_sk
JOIN warehouse w       ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp       ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we       ON ws.ws_web_site_sk = we.web_site_sk
JOIN customer c        ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_returns wr    ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r           ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = ws.ws_order_number
LEFT JOIN call_center cc     ON cc.cc_closed_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp    ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN inventory i        ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
WHERE t.t_minute IN (14, 19, 3)
  AND we.web_state = 'CA'
  AND w.w_city = 'Los Angeles'
  AND wp.wp_type = 'D'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr_sub
        WHERE cr_sub.cr_warehouse_sk = w.w_warehouse_sk
          AND cr_sub.cr_return_quantity > 0
    )
GROUP BY GROUPING SETS (
    (d.d_year, w.w_warehouse_name, ws.ws_web_page_sk, c.c_preferred_cust_flag),
    (d.d_year, w.w_warehouse_name, ws.ws_web_page_sk),
    (d.d_year, w.w_warehouse_name),
    (d.d_year),
    ()
)
ORDER BY total_quantity DESC
LIMIT 100
