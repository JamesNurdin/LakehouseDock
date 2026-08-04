WITH filtered_ws AS (
    SELECT ws.*
    FROM web_sales ws
    WHERE ws.ws_warehouse_sk IN (
        SELECT w_warehouse_sk
        FROM warehouse
        WHERE w_city = 'Oakland'
    )
)
SELECT
    ca.ca_city,
    p.p_promo_name,
    cp.cp_department,
    td.t_hour,
    s.s_store_name,
    ib.ib_lower_bound,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(ws.ws_net_paid) AS min_net_paid,
    MAX(ws.ws_net_paid) AS max_net_paid
FROM filtered_ws ws
JOIN time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
  ON ws.ws_item_sk = cr.cr_item_sk
  AND ws.ws_order_number = cr.cr_order_number
LEFT JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN store_returns sr
  ON td.t_time_sk = sr.sr_return_time_sk
LEFT JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN inventory i
  ON w.w_warehouse_sk = i.inv_warehouse_sk
  AND i.inv_date_sk = td.t_time_sk
LEFT JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
  AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    ca.ca_city = 'Oakland'
    AND ib.ib_lower_bound >= 80000
    AND p.p_discount_active = 'Y'
    AND td.t_hour BETWEEN 9 AND 17
    AND cp.cp_department = 'Electronics'
GROUP BY CUBE (
    ca.ca_city,
    p.p_promo_name,
    cp.cp_department,
    td.t_hour,
    s.s_store_name,
    ib.ib_lower_bound
)
ORDER BY total_net_paid DESC
LIMIT 100
