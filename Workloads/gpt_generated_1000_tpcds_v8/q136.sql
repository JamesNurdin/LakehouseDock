WITH base AS (
  SELECT
    s.s_store_name AS s_store_name,
    s.s_state AS s_state,
    d_sales.d_year AS d_year,
    i.i_item_id AS i_item_id,
    i.i_color AS i_color,
    w.w_warehouse_name AS w_warehouse_name,
    cc.cc_name AS cc_name,
    sm.sm_type AS sm_type,
    r.r_reason_desc AS r_reason_desc,
    ss.ss_quantity AS ss_quantity,
    ss.ss_ext_sales_price AS ss_ext_sales_price,
    ss.ss_net_profit AS ss_net_profit,
    sr.sr_return_quantity AS sr_return_quantity,
    cr.cr_return_amount AS cr_return_amount,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
  FROM store_sales ss
  JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d_sales.d_date_sk
  LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sales.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
  LEFT JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
  WHERE d_sales.d_year = 2001
    AND i.i_color IN ('red', 'blue')
    AND w.w_county = 'Williamson County'
    AND s.s_state = 'TX'
    AND sm.sm_type = 'AIR'
    AND ca.ca_state = 'TX'
),
sales_agg AS (
  SELECT
    s_store_name,
    d_year,
    profit_flag,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    COUNT(*) AS transaction_cnt,
    CASE WHEN SUM(ss_ext_sales_price) > 200000 THEN 'High' ELSE 'Normal' END AS sales_level
  FROM base
  GROUP BY GROUPING SETS (
    (s_store_name, d_year, profit_flag),
    (s_store_name, d_year),
    (d_year),
    ()
  )
)
SELECT
  s_store_name,
  d_year,
  profit_flag,
  total_sales,
  total_profit,
  transaction_cnt,
  sales_level,
  RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
  SUM(total_sales) OVER (PARTITION BY d_year) AS sales_year_total,
  (SELECT COUNT(*) FROM catalog_returns cr_sub WHERE cr_sub.cr_return_amount > 0) AS total_positive_returns
FROM sales_agg
WHERE total_sales IS NOT NULL
ORDER BY d_year, sales_rank
LIMIT 100
