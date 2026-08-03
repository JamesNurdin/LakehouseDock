WITH
  -- Aggregate returns per item and reason for the year 2001
  returns_agg AS (
    SELECT
      cr_item_sk,
      cr_reason_sk,
      SUM(cr_return_quantity)   AS total_return_qty,
      SUM(cr_return_amount)     AS total_return_amount
    FROM catalog_returns
    WHERE cr_returned_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY cr_item_sk, cr_reason_sk
  ),
  -- Aggregate sales per item for the same year
  sales_agg AS (
    SELECT
      ws_item_sk,
      SUM(ws_quantity)          AS total_sales_qty,
      SUM(ws_ext_sales_price)   AS total_sales_amount,
      SUM(ws_net_profit)        AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY ws_item_sk
  )
SELECT
  sub.item_id,
  sub.category,
  SUM(sub.return_qty)               AS return_qty,
  SUM(sub.return_amt)               AS return_amt,
  SUM(sub.sales_qty)                AS sales_qty,
  SUM(sub.sales_amt)                AS sales_amt,
  SUM(sub.net_profit)               AS net_profit,
  CASE
    WHEN SUM(sub.sales_amt) = 0 THEN NULL
    ELSE SUM(sub.return_amt) / SUM(sub.sales_amt)
  END                               AS return_to_sales_ratio,
  MAX(sub.last_return_date)         AS last_return_date,
  AVG(sub.avg_price)                AS avg_price
FROM (
  -- 1️⃣ Returns side – joins many dimensional tables
  SELECT
    i.i_item_id                                 AS item_id,
    i.i_category                                AS category,
    r.total_return_qty                         AS return_qty,
    r.total_return_amount                      AS return_amt,
    0                                           AS sales_qty,
    0.0                                         AS sales_amt,
    0.0                                         AS net_profit,
    d_return.d_date                             AS last_return_date,
    (SELECT AVG(ws_sales_price)
       FROM web_sales
       WHERE ws_item_sk = i.i_item_sk)        AS avg_price
  FROM returns_agg r
  JOIN catalog_returns cr        ON r.cr_item_sk = cr.cr_item_sk AND r.cr_reason_sk = cr.cr_reason_sk
  JOIN item i                     ON r.cr_item_sk = i.i_item_sk
  JOIN reason re                  ON r.cr_reason_sk = re.r_reason_sk
  JOIN ship_mode sm               ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w                ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN call_center cc             ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN date_dim d_return          ON cr.cr_returned_date_sk = d_return.d_date_sk
  JOIN time_dim t_return          ON cr.cr_returned_time_sk = t_return.t_time_sk
  JOIN customer_address ca       ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
  -- second use of date_dim for the call‑center open date (different alias)
  JOIN date_dim d_cc_open         ON cc.cc_open_date_sk = d_cc_open.d_date_sk
  WHERE sm.sm_ship_mode_id = 'AAAAAAAAPAAAAAAA'

  UNION

  -- 2️⃣ Sales side – joins the remaining dimensional tables
  SELECT
    i2.i_item_id                                AS item_id,
    i2.i_category                               AS category,
    0                                           AS return_qty,
    0.0                                         AS return_amt,
    s.total_sales_qty                           AS sales_qty,
    s.total_sales_amount                        AS sales_amt,
    s.total_net_profit                          AS net_profit,
    NULL                                        AS last_return_date,
    (SELECT AVG(ws_sales_price)
       FROM web_sales
       WHERE ws_item_sk = i2.i_item_sk)       AS avg_price
  FROM sales_agg s
  JOIN item i2                     ON s.ws_item_sk = i2.i_item_sk
  JOIN web_sales ws                ON ws.ws_item_sk = i2.i_item_sk
  JOIN date_dim d_sold             ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold             ON ws.ws_sold_time_sk = t_sold.t_time_sk
  JOIN customer c                  ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca2       ON ws.ws_bill_addr_sk = ca2.ca_address_sk
  JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
  JOIN income_band ib2            ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
  JOIN ship_mode sm2              ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
  JOIN warehouse w2               ON ws.ws_warehouse_sk = w2.w_warehouse_sk
  JOIN web_page wp                ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we                ON ws.ws_web_site_sk = we.web_site_sk
  -- extra date_dim joins with different aliases
  JOIN date_dim d_site_open       ON we.web_open_date_sk = d_site_open.d_date_sk
  JOIN date_dim d_page_creation   ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
  WHERE we.web_country = 'United States'
) sub
GROUP BY sub.item_id, sub.category
ORDER BY return_to_sales_ratio DESC NULLS LAST
LIMIT 100
