WITH
  ss_agg AS (
    SELECT
      ss_store_sk,
      SUM(ss_net_profit) AS total_net_profit,
      COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_ext_tax > 20
      AND ss_wholesale_cost < 100
    GROUP BY ss_store_sk
  ),
  order_diff AS (
    SELECT ws_order_number
    FROM web_sales
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
  ),
  base AS (
    SELECT
      cr.cr_return_amount,
      cr.cr_returned_date_sk,
      c.c_customer_sk,
      c.c_birth_year,
      cd.cd_demo_sk,
      hd.hd_demo_sk,
      ca.ca_address_sk,
      sm.sm_ship_mode_sk,
      r.r_reason_sk,
      ss.ss_store_sk,
      ss.ss_ext_tax,
      s.s_store_id,
      s.s_city,
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      wr.wr_order_number
    FROM catalog_returns cr
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    WHERE cr.cr_return_amount > 50
      AND ss.ss_ext_tax > 20
      AND sm.sm_type = 'AIR'
      AND ib.ib_upper_bound > 60000
  )
SELECT
  s_store_id,
  s_city,
  total_net_profit,
  sales_cnt,
  CASE WHEN total_net_profit > 10000 THEN 'High' ELSE 'Medium' END AS profit_category,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
  cr_return_amount,
  ws_order_number
FROM (
  SELECT
    b.s_store_id,
    b.s_city,
    a.total_net_profit,
    a.sales_cnt,
    b.cr_return_amount,
    b.ws_order_number,
    b.wr_order_number,
    b.c_birth_year
  FROM base b
  JOIN ss_agg a ON a.ss_store_sk = b.ss_store_sk
  WHERE b.wr_order_number IS NULL
    AND b.ws_order_number IN (SELECT ws_order_number FROM order_diff)
    AND b.c_birth_year > 1980
) t1
UNION DISTINCT
SELECT
  s_store_id,
  s_city,
  total_net_profit,
  sales_cnt,
  CASE WHEN total_net_profit > 10000 THEN 'High' ELSE 'Medium' END AS profit_category,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
  cr_return_amount,
  ws_order_number
FROM (
  SELECT
    b.s_store_id,
    b.s_city,
    a.total_net_profit,
    a.sales_cnt,
    b.cr_return_amount,
    b.ws_order_number,
    b.wr_order_number,
    b.c_birth_year
  FROM base b
  JOIN ss_agg a ON a.ss_store_sk = b.ss_store_sk
  WHERE b.wr_order_number IS NOT NULL
    AND b.ws_order_number NOT IN (SELECT ws_order_number FROM order_diff)
    AND b.c_birth_year > 1980
) t2
ORDER BY profit_rank, s_store_id
