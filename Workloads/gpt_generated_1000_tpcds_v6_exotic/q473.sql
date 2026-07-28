WITH sales_agg AS (
  SELECT
    cc.cc_call_center_id AS call_center_id,
    d.d_year AS year,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt
  FROM
    catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  WHERE
    d.d_year = 2001
    AND ca.ca_state = 'CA'
    AND p.p_response_target = 1
  GROUP BY
    cc.cc_call_center_id,
    d.d_year
)
SELECT
  call_center_id,
  year,
  total_profit,
  total_sales,
  order_cnt,
  AVG(total_profit) OVER (PARTITION BY year) AS avg_profit_by_year,
  RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM
  sales_agg
WHERE
  total_sales > (
    SELECT
      AVG(cs2.cs_ext_sales_price) * 0.5
    FROM
      catalog_sales cs2
      JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE
      d2.d_year = sales_agg.year
  )
ORDER BY
  total_profit DESC
LIMIT 100
