WITH base AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ws.ws_warehouse_sk,
    ws.ws_promo_sk,
    ws.ws_web_page_sk,
    ws.ws_web_site_sk,
    ws.ws_bill_hdemo_sk,
    ws.ws_bill_addr_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    i.i_brand,
    i.i_category,
    p.p_channel_email,
    p.p_discount_active,
    w.w_state,
    ca.ca_state,
    cc.cc_state,
    d.d_year,
    d.d_month_seq,
    wp.wp_type,
    ws_site.web_name
  FROM web_sales ws
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
  LEFT JOIN call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#23'
    AND p.p_channel_email = 'Y'
    AND w.w_state = 'CA'
),

sales_agg AS (
  SELECT
    d_year,
    i_brand,
    w_state,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_quantity) AS total_quantity,
    NULL AS total_return_qty,
    NULL AS total_return_amt,
    SUM(CASE WHEN p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_discount_cnt,
    'sales' AS metric_type
  FROM base
  GROUP BY GROUPING SETS (
    (d_year, i_brand, w_state),
    (d_year, i_brand),
    (d_year),
    ()
  )
),

returns_agg AS (
  SELECT
    d_year,
    i_brand,
    w_state,
    NULL AS total_sales,
    NULL AS total_quantity,
    SUM(wr_return_quantity) AS total_return_qty,
    SUM(wr_return_amt) AS total_return_amt,
    SUM(CASE WHEN p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_discount_cnt,
    'returns' AS metric_type
  FROM base
  WHERE wr_return_quantity IS NOT NULL
  GROUP BY GROUPING SETS (
    (d_year, i_brand, w_state),
    (d_year, i_brand),
    (d_year),
    ()
  )
),

combined AS (
  SELECT * FROM sales_agg
  UNION ALL
  SELECT * FROM returns_agg
)

SELECT
  d_year,
  i_brand,
  w_state,
  metric_type,
  total_sales,
  total_quantity,
  total_return_qty,
  total_return_amt,
  active_discount_cnt,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY COALESCE(total_sales,0) + COALESCE(total_return_amt,0) DESC) AS rank_in_year
FROM combined
ORDER BY d_year DESC, rank_in_year
LIMIT 100
