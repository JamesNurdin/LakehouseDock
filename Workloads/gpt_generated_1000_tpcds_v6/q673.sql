WITH
  catalog_ret AS (
    SELECT
      cr.cr_return_amount,
      cr.cr_net_loss,
      d.d_year,
      d.d_month_seq,
      sm.sm_type,
      w.w_city,
      r.r_reason_desc,
      ca_ret.ca_state
    FROM catalog_returns cr
    JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t               ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c_ref          ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer c_ret          ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN ship_mode sm            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w             ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r                ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND ca_ret.ca_state = 'CA'
      AND sm.sm_type = 'EXPRESS'
      AND w.w_city = 'Chicago'
      AND r.r_reason_desc = 'Damaged'
  ),

  store_ret AS (
    SELECT
      sr.sr_return_amt,
      sr.sr_net_loss,
      d.d_year,
      d.d_month_seq,
      s.s_store_name,
      s.s_state
    FROM store_returns sr
    JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t               ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c              ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca     ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s                 ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r                ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'TX'
      AND d.d_year = 2002
  ),

  store_sales_agg AS (
    SELECT
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      d.d_year,
      d.d_month_seq,
      s.s_store_name,
      c.c_customer_id
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s                 ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c              ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca     ON ss.ss_addr_sk = ca.ca_address_sk
  ),

  web_sales_agg AS (
    SELECT
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      d.d_year,
      d.d_month_seq,
      sm.sm_type,
      w.w_city,
      wp.wp_link_count
    FROM web_sales ws
    JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w             ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp             ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c              ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca     ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE wp.wp_link_count > 10
      AND sm.sm_contract = 'fop0bcSd91J26IVpR'
  ),

  preferred_customers AS (
    SELECT DISTINCT c.c_customer_id
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_country = 'United States'
  )

SELECT
  t.d_year,
  t.d_month_seq,
  t.s_store_name,
  SUM(t.cr_return_amount)      AS total_return_amount,
  SUM(t.ss_ext_sales_price)    AS total_store_sales,
  SUM(t.ws_ext_sales_price)    AS total_web_sales,
  COUNT(DISTINCT t.c_customer_id) AS distinct_customers,
  AVG(t.cr_net_loss)           AS avg_return_loss,
  MIN(t.cr_return_amount)      AS min_return_amount,
  MAX(t.cr_return_amount)      AS max_return_amount
FROM (
  SELECT
    cr.d_year,
    cr.d_month_seq,
    ss.s_store_name,
    cr.cr_return_amount,
    cr.cr_net_loss,
    ss.ss_ext_sales_price,
    ws.ws_ext_sales_price,
    ss.c_customer_id
  FROM catalog_ret cr
  JOIN store_ret sr   ON cr.d_year = sr.d_year   AND cr.d_month_seq = sr.d_month_seq
  JOIN store_sales_agg ss ON cr.d_year = ss.d_year AND cr.d_month_seq = ss.d_month_seq
  JOIN web_sales_agg ws   ON cr.d_year = ws.d_year AND cr.d_month_seq = ws.d_month_seq
  JOIN preferred_customers pc ON ss.c_customer_id = pc.c_customer_id
) t
GROUP BY ROLLUP (t.s_store_name, t.d_year, t.d_month_seq)
ORDER BY t.s_store_name NULLS LAST, t.d_year, t.d_month_seq
