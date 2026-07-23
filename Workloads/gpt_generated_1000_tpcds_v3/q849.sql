SELECT
    d.d_year,
    s.s_store_name,
    wsite.web_name,
    CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS order_size_category,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    AVG(wr.wr_fee) AS avg_return_fee,
    MIN(ib.ib_lower_bound) AS min_income_lower,
    MAX(ib.ib_upper_bound) AS max_income_upper
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
WHERE d.d_year = 2002
  AND s.s_city = 'Sycamore'
  AND ib.ib_lower_bound = 30000
  AND cs.cs_quantity > 5
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_fee > 70
    )
GROUP BY d.d_year, s.s_store_name, wsite.web_name,
         CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END
LIMIT 100
