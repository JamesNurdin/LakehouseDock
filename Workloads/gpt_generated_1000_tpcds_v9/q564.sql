WITH
    store_ret AS (
        SELECT
            sr.sr_customer_sk AS cust_sk,
            SUM(sr.sr_net_loss) AS store_net_loss
        FROM store_returns sr
        JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
        JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
        WHERE d_sr.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
          AND t_sr.t_meal_time = 'lunch'
          AND s.s_state = 'CA'
          AND r_sr.r_reason_desc LIKE '%Damage%'
        GROUP BY sr.sr_customer_sk
    ),
    catalog_ret AS (
        SELECT
            cr.cr_returning_customer_sk AS cust_sk,
            SUM(cr.cr_net_loss) AS catalog_net_loss
        FROM catalog_returns cr
        JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
        JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
        WHERE d_cr.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
          AND t_cr.t_meal_time = 'dinner'
          AND cc.cc_state = 'CA'
          AND w.w_city = 'Seattle'
          AND r_cr.r_reason_desc LIKE '%Defect%'
        GROUP BY cr.cr_returning_customer_sk
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_bill_customer_sk AS cust_sk,
            SUM(ws.ws_net_profit) AS total_web_profit
        FROM web_sales ws
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        WHERE d_ws.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
          AND wp.wp_type = 'Content'
          AND ws_site.web_country = 'United States'
        GROUP BY ws.ws_bill_customer_sk
    ),
    web_ret AS (
        SELECT
            wr.wr_returning_customer_sk AS cust_sk,
            SUM(wr.wr_net_loss) AS web_net_loss
        FROM web_returns wr
        JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
        JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
        JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
                         AND wr.wr_order_number = ws.ws_order_number
        WHERE d_wr.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
          AND r_wr.r_reason_desc LIKE '%Return%'
          AND wp_wr.wp_type = 'Landing'
        GROUP BY wr.wr_returning_customer_sk
    )
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(sr.store_net_loss, 0) AS store_net_loss,
    COALESCE(cr.catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(wsagg.total_web_profit, 0) AS web_profit,
    COALESCE(wr.web_net_loss, 0) AS web_return_loss,
    (COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0) - COALESCE(wsagg.total_web_profit, 0)) AS total_net_loss,
    DENSE_RANK() OVER (ORDER BY (COALESCE(sr.store_net_loss, 0) + COALESCE(cr.catalog_net_loss, 0) + COALESCE(wr.web_net_loss, 0) - COALESCE(wsagg.total_web_profit, 0)) DESC) AS loss_rank
FROM customer c
LEFT JOIN store_ret sr ON c.c_customer_sk = sr.cust_sk
LEFT JOIN catalog_ret cr ON c.c_customer_sk = cr.cust_sk
LEFT JOIN web_sales_agg wsagg ON c.c_customer_sk = wsagg.cust_sk
LEFT JOIN web_ret wr ON c.c_customer_sk = wr.cust_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_country = 'United States'
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name,
         sr.store_net_loss, cr.catalog_net_loss, wsagg.total_web_profit, wr.web_net_loss
HAVING (COALESCE(sr.store_net_loss,0) + COALESCE(cr.catalog_net_loss,0) + COALESCE(wr.web_net_loss,0) - COALESCE(wsagg.total_web_profit,0)) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
