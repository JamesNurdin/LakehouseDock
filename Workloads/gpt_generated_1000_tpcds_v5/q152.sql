WITH base AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_store_sk,
    ss.ss_net_profit,
    ss.ss_ext_sales_price,
    ss.ss_quantity,
    d.d_year,
    d.d_date,
    s.s_store_name,
    s.s_state,
    cc.cc_name,
    cc.cc_employees,
    cp.cp_type,
    cp.cp_department,
    ws.web_name,
    ws.web_state,
    wp.wp_type,
    wp.wp_url,
    i.inv_quantity_on_hand
  FROM tpcds.store_sales ss
  JOIN tpcds.date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN tpcds.call_center cc
    ON d.d_date_sk = cc.cc_closed_date_sk
  JOIN tpcds.catalog_page cp
    ON d.d_date_sk = cp.cp_end_date_sk
  JOIN tpcds.web_site ws
    ON d.d_date_sk = ws.web_open_date_sk
  JOIN tpcds.web_page wp
    ON d.d_date_sk = wp.wp_creation_date_sk
  JOIN tpcds.inventory i
    ON d.d_date_sk = i.inv_date_sk
  WHERE d.d_year = 2002
    AND ss.ss_net_profit > 0
    AND s.s_state IN ('CA', 'TX')
    AND cc.cc_employees > 1000000
    AND cp.cp_type = 'Electronics'
    AND ws.web_state = 'NY'
    AND i.inv_quantity_on_hand > 0
)
SELECT
  d_year,
  s_store_name,
  cc_name,
  cp_department,
  web_name,
  wp_type,
  inv_quantity_on_hand,
  ss_net_profit,
  ss_ext_sales_price,
  SUM(ss_net_profit) OVER (
    PARTITION BY s_store_name, d_year
    ORDER BY d_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_profit,
  RANK() OVER (
    PARTITION BY d_year
    ORDER BY ss_ext_sales_price DESC
  ) AS sales_rank
FROM base
ORDER BY d_year, sales_rank
LIMIT 100
