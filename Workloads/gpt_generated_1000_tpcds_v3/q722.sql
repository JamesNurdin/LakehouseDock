WITH base AS (
  SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_brand,
    d.d_year,
    ws.ws_web_site_sk,
    wsit.web_name,
    ws.ws_net_profit,
    ws.ws_net_paid,
    wr.wr_refunded_cash,
    sm.sm_contract,
    r.r_reason_desc,
    cc.cc_state
  FROM tpcds.catalog_returns cr
  JOIN tpcds.date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN tpcds.item i
    ON cr.cr_item_sk = i.i_item_sk
  JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_order_number = ws.ws_order_number
    AND wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_reason_sk = r.r_reason_sk
  JOIN tpcds.web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
    AND wsit.web_open_date_sk = d.d_date_sk
  WHERE
    d.d_year BETWEEN 1998 AND 2000
    AND sm.sm_contract LIKE 'HVDF%'
    AND r.r_reason_desc = 'Customer Not Satisfied'
    AND cc.cc_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND wr.wr_refunded_cash > 100
), agg AS (
  SELECT
    i_item_sk,
    i_product_name,
    i_brand,
    d_year,
    web_name,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(wr_refunded_cash) AS total_refunded_cash,
    COUNT(DISTINCT ws_web_site_sk) AS distinct_web_sites
  FROM base
  GROUP BY
    i_item_sk,
    i_product_name,
    i_brand,
    d_year,
    web_name
  HAVING SUM(ws_net_profit) > 0
)
SELECT
  i_item_sk,
  i_product_name,
  i_brand,
  d_year,
  web_name,
  total_net_profit,
  total_net_paid,
  total_refunded_cash,
  distinct_web_sites,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year, profit_rank
LIMIT 100
