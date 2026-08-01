WITH sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    i.inv_item_sk,
    d.d_date,
    s.s_store_name,
    ss.ss_ticket_number,
    ss.ss_net_paid,
    cs.cs_net_paid,
    cr.cr_net_loss,
    ws.ws_order_number,
    ws.ws_net_paid,
    wr.wr_net_loss,
    cc.cc_name,
    cp.cp_department,
    hd.hd_income_band_sk,
    lc.same_manager_cc,
    (
        SELECT SUM(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
    ) AS total_web_paid_by_customer,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ss.ss_net_paid DESC) AS sales_rank
FROM sampled_inventory i
JOIN date_dim d
  ON i.inv_date_sk = d.d_date_sk
FULL OUTER JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
FULL OUTER JOIN store_sales ss
  ON ss.ss_store_sk = s.s_store_sk
 AND ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN catalog_sales cs
  ON cs.cs_bill_customer_sk = c.c_customer_sk
 AND cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_returned_date_sk = d.d_date_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
 AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_returned_date_sk = d.d_date_sk
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS same_manager_cc
    FROM call_center cc2
    WHERE cc2.cc_market_manager = cc.cc_market_manager
) lc
WHERE d.d_year = 2001
  AND hd.hd_income_band_sk IN (9, 11, 17)
  AND cc.cc_gmt_offset > 0
ORDER BY total_web_paid_by_customer DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
