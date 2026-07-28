WITH ws_agg AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_ws_sales,
        COUNT(*) AS ws_cnt
    FROM web_sales ws
    WHERE ws.ws_sold_time_sk IN (
        SELECT t_time_sk
        FROM time_dim
        WHERE t_hour BETWEEN 8 AND 12
    )
    GROUP BY ws.ws_sold_time_sk, ws.ws_web_site_sk
)
SELECT
    cp.cp_department,
    wsite.web_mkt_id,
    td.t_hour,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    ws_agg.total_ws_sales,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    ws_agg.ws_cnt,
    (
        SELECT AVG(cs2.cs_ext_discount_amt)
        FROM catalog_sales cs2
        WHERE cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
    ) AS avg_catalog_discount
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN ws_agg
    ON ws_agg.ws_sold_time_sk = td.t_time_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE cp.cp_department = 'Books'
  AND ca.ca_state = 'CA'
  AND td.t_am_pm = 'PM'
  AND wsite.web_mkt_id IN (1, 2, 3)
  AND NOT EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_web_page_sk = ws.ws_web_page_sk
          AND wp2.wp_type = 'A'
    )
GROUP BY cp.cp_department,
         wsite.web_mkt_id,
         td.t_hour,
         ws_agg.total_ws_sales,
         ws_agg.ws_cnt,
         cp.cp_catalog_page_sk
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY catalog_sales DESC
LIMIT 100
