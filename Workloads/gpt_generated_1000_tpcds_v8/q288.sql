WITH store_only_customers AS (
    SELECT ss.ss_customer_sk
    FROM store_sales ss
    EXCEPT
    SELECT ws.ws_bill_customer_sk
    FROM web_sales ws
)
SELECT
    cc.cc_name,
    i.i_category,
    td.t_hour,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(ca.ca_zip) AS min_customer_zip,
    MAX(sr.sr_return_amt) AS max_return_amount
FROM call_center cc
JOIN catalog_sales cs
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_sold_time_sk = td.t_time_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN store_only_customers soc
  ON ss.ss_customer_sk = soc.ss_customer_sk
WHERE cc.cc_state = 'CA'
  AND ca.ca_county = 'York County'
  AND ib.ib_upper_bound = 120000
  AND td.t_hour BETWEEN 9 AND 17
  AND i.i_color = 'Red'
  AND i.i_current_price > (
        SELECT AVG(i2.i_current_price)
        FROM item i2
        WHERE i2.i_brand_id = 5
    )
GROUP BY cc.cc_name, i.i_category, td.t_hour
ORDER BY total_net_paid DESC
LIMIT 100
