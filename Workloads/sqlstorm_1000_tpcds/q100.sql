WITH store_agg AS (
  SELECT
    d.d_year,
    d.d_moy AS month_num,
    s.s_state AS region,
    i.i_category AS category,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_coupon_amt) AS total_coupon,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    approx_distinct(ss.ss_customer_sk) AS distinct_customers,
    approx_distinct(ss.ss_item_sk) AS distinct_items
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
    AND ss.ss_store_sk = sr.sr_store_sk
    AND d.d_date_sk = sr.sr_returned_date_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_moy, s.s_state, i.i_category
),
catalog_agg AS (
  SELECT
    d.d_year,
    d.d_moy AS month_num,
    cc.cc_state AS region,
    i.i_category AS category,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_coupon_amt) AS total_coupon,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    approx_distinct(cs.cs_bill_customer_sk) AS distinct_customers,
    approx_distinct(cs.cs_item_sk) AS distinct_items
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
    AND d.d_date_sk = cr.cr_returned_date_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_moy, cc.cc_state, i.i_category
),
web_agg AS (
  SELECT
    d.d_year,
    d.d_moy AS month_num,
    wsite.web_state AS region,
    i.i_category AS category,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_coupon_amt) AS total_coupon,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    approx_distinct(ws.ws_bill_customer_sk) AS distinct_customers,
    approx_distinct(ws.ws_item_sk) AS distinct_items
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
    AND d.d_date_sk = wr.wr_returned_date_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, d.d_moy, wsite.web_state, i.i_category
),
combined AS (
  SELECT d_year, month_num, region, category, total_net_paid, total_net_profit, total_discount, total_coupon, total_quantity, total_return_loss, distinct_customers, distinct_items FROM store_agg
  UNION ALL
  SELECT d_year, month_num, region, category, total_net_paid, total_net_profit, total_discount, total_coupon, total_quantity, total_return_loss, distinct_customers, distinct_items FROM catalog_agg
  UNION ALL
  SELECT d_year, month_num, region, category, total_net_paid, total_net_profit, total_discount, total_coupon, total_quantity, total_return_loss, distinct_customers, distinct_items FROM web_agg
)
SELECT
  d_year,
  month_num,
  region,
  category,
  net_paid,
  net_profit,
  discount,
  coupon,
  quantity,
  return_loss,
  net_revenue,
  distinct_customers,
  distinct_items,
  revenue_rank,
  (net_revenue * 100.0) / SUM(net_revenue) OVER (PARTITION BY d_year, month_num) AS net_revenue_pct
FROM (
  SELECT
    d_year,
    month_num,
    region,
    category,
    SUM(total_net_paid) AS net_paid,
    SUM(total_net_profit) AS net_profit,
    SUM(total_discount) AS discount,
    SUM(total_coupon) AS coupon,
    SUM(total_quantity) AS quantity,
    SUM(total_return_loss) AS return_loss,
    (SUM(total_net_paid) - SUM(total_return_loss)) AS net_revenue,
    SUM(distinct_customers) AS distinct_customers,
    SUM(distinct_items) AS distinct_items,
    RANK() OVER (PARTITION BY d_year, month_num ORDER BY (SUM(total_net_paid) - SUM(total_return_loss)) DESC) AS revenue_rank
  FROM combined
  GROUP BY d_year, month_num, region, category
) t
ORDER BY d_year, month_num, revenue_rank
