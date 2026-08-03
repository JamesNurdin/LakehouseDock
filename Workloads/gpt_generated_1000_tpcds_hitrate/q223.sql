WITH base AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_quantity,
    ss.ss_net_paid,
    i.i_item_id,
    i.i_category,
    i.i_units,
    i.i_formulation,
    c.c_customer_id,
    c.c_preferred_cust_flag,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    sm.sm_type,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wp.wp_link_count,
    wp.wp_type
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    AND wp.wp_customer_sk = c.c_customer_sk
  WHERE i.i_units = 'Each'
    AND i.i_formulation LIKE '%goldenrod%'
    AND sm.sm_type = 'AIR'
    AND wp.wp_link_count > 10
),
agg AS (
  SELECT
    i_category,
    SUM(ss_quantity) AS total_qty_sold,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(cr_return_amount) AS total_cr_return,
    SUM(wr_return_amt) AS total_wr_return,
    COUNT(DISTINCT c_customer_id) AS uniq_customers,
    AVG(ss_net_paid) AS avg_net_paid
  FROM base
  GROUP BY i_category
  HAVING SUM(ss_quantity) > 1000
)
SELECT
  a.i_category,
  a.total_qty_sold,
  a.total_net_paid,
  a.total_cr_return,
  a.total_wr_return,
  a.uniq_customers,
  a.avg_net_paid,
  ROW_NUMBER() OVER (ORDER BY a.total_net_paid DESC) AS rn,
  SUM(a.total_net_paid) OVER (ORDER BY a.total_net_paid DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
  LAG(a.total_qty_sold) OVER (ORDER BY a.total_net_paid DESC) AS prev_qty_sold,
  (SELECT MAX(avg_net_paid) FROM agg) AS max_avg_net_paid
FROM agg a
ORDER BY a.total_net_paid DESC
LIMIT 100
