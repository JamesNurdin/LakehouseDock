WITH
  avg_discount AS (
    SELECT AVG(cs_ext_discount_amt) AS avg_disc
    FROM catalog_sales
    WHERE cs_ext_discount_amt > 0
  ),
  sales AS (
    SELECT
      d_sales.d_year AS year,
      CAST(NULL AS varchar) AS store,
      'sales' AS metric,
      SUM(cs.cs_net_paid) AS total_amount,
      COUNT(*) AS transaction_count,
      (SELECT avg_disc FROM avg_discount) AS avg_discount
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT OUTER JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d_sales.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cs.cs_ext_sales_price > 500
      AND wp.wp_max_ad_count >= 2
      AND cc.cc_name = 'Call Center 1'
    GROUP BY d_sales.d_year
  ),
  returns AS (
    SELECT
      d_ret.d_year AS year,
      st.s_store_name AS store,
      'returns' AS metric,
      SUM(sr.sr_return_amt) AS total_amount,
      COUNT(*) AS transaction_count,
      (SELECT avg_disc FROM avg_discount) AS avg_discount
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2 ON sr.sr_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2 ON sr.sr_addr_sk = ca2.ca_address_sk
    WHERE d_ret.d_year = 2001
      AND st.s_state = 'CA'
      AND r.r_reason_desc = 'Damaged'
      AND sr.sr_return_amt > 100
      AND st.s_tax_percentage < 5
    GROUP BY d_ret.d_year, st.s_store_name
  ),
  combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
  )
SELECT
  year,
  store,
  metric,
  total_amount,
  transaction_count,
  avg_discount,
  ROW_NUMBER() OVER (PARTITION BY store ORDER BY total_amount DESC) AS store_rank
FROM combined
ORDER BY year DESC, total_amount DESC
