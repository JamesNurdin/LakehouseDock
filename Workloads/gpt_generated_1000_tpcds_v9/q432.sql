WITH sales_agg AS (
  SELECT
    s.s_store_name AS store_name,
    s.s_state AS state,
    cc.cc_division AS division,
    SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
    SUM(ws.ws_net_paid) AS web_sales_net_paid,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
  FROM catalog_sales cs
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN store_returns sr
    ON sr.sr_return_time_sk = t.t_time_sk
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  WHERE
    cc.cc_division IN (2, 4, 5) AND
    c.c_birth_year BETWEEN 1970 AND 1980 AND
    i.i_current_price > 50.00 AND
    p.p_discount_active = 'Y' AND
    s.s_tax_percentage >= 0.05 AND
    t.t_hour BETWEEN 8 AND 17 AND
    ws_site.web_state = 'CA'
  GROUP BY
    GROUPING SETS (
      (s.s_store_name, s.s_state, cc.cc_division),
      (s.s_state, cc.cc_division),
      (cc.cc_division),
      ()
    )
  HAVING
    SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid) - SUM(sr.sr_return_amt) > 10000
)
SELECT
  store_name,
  state,
  division,
  catalog_sales_net_paid,
  web_sales_net_paid,
  total_return_amount,
  (catalog_sales_net_paid + web_sales_net_paid - total_return_amount) AS net_revenue,
  RANK() OVER (PARTITION BY division ORDER BY (catalog_sales_net_paid + web_sales_net_paid - total_return_amount) DESC) AS revenue_rank_in_division,
  ROW_NUMBER() OVER (ORDER BY (catalog_sales_net_paid + web_sales_net_paid - total_return_amount) DESC) AS overall_revenue_rownum
FROM sales_agg
ORDER BY net_revenue DESC
LIMIT 100
