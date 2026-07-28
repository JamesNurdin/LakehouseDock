WITH
  store_sales_agg AS (
    SELECT
      ss.ss_customer_sk,
      SUM(ss.ss_net_paid) AS store_net_paid
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
                         AND ss.ss_item_sk = sr.sr_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE i.i_wholesale_cost > 50
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_customer_sk
  ),
  catalog_sales_agg AS (
    SELECT
      cs.cs_bill_customer_sk AS cust_sk,
      SUM(cs.cs_net_paid) AS catalog_net_paid
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE i.i_wholesale_cost > 50
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cs.cs_bill_customer_sk
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS cust_sk,
      SUM(ws.ws_net_paid) AS web_net_paid
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE i.i_wholesale_cost > 50
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_bill_customer_sk
  )
SELECT DISTINCT
  c.c_customer_id,
  c.c_birth_country,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  (COALESCE(ssag.store_net_paid, 0) +
   COALESCE(csag.catalog_net_paid, 0) +
   COALESCE(wsag.web_net_paid, 0)) AS total_net_paid,
  RANK() OVER (ORDER BY (COALESCE(ssag.store_net_paid, 0) +
                         COALESCE(csag.catalog_net_paid, 0) +
                         COALESCE(wsag.web_net_paid, 0)) DESC) AS revenue_rank
FROM customer c
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN store_sales_agg ssag ON c.c_customer_sk = ssag.ss_customer_sk
LEFT JOIN catalog_sales_agg csag ON c.c_customer_sk = csag.cust_sk
LEFT JOIN web_sales_agg wsag ON c.c_customer_sk = wsag.cust_sk
WHERE c.c_birth_country = 'JAPAN'
  AND NOT EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
      )
  AND (COALESCE(ssag.store_net_paid, 0) +
       COALESCE(csag.catalog_net_paid, 0) +
       COALESCE(wsag.web_net_paid, 0)) > 1000
ORDER BY revenue_rank
LIMIT 100
