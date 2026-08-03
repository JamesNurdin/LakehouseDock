WITH base AS (
  SELECT
    d.d_year,
    cc.cc_state,
    cd.cd_gender,
    cs.cs_net_paid,
    ss.ss_net_paid,
    ws.ws_net_paid,
    cr.cr_return_amount,
    sr.sr_return_amt,
    inv.inv_quantity_on_hand
  FROM tpcds.date_dim d
  LEFT JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_order_number = cs.cs_order_number
  LEFT JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN tpcds.store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN tpcds.web_site we
    ON we.web_open_date_sk = d.d_date_sk
  LEFT JOIN tpcds.call_center cc
    ON cc.cc_open_date_sk = d.d_date_sk
   AND cc.cc_call_center_sk = cs.cs_call_center_sk
  LEFT JOIN tpcds.customer_demographics cd
    ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
  LEFT JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    AND cc.cc_mkt_class LIKE 'Major%'
    AND cd.cd_gender = 'M'
    AND cs.cs_quantity > 5
    AND inv.inv_quantity_on_hand > 0
    AND we.web_city = 'Washington'
),
distinct_base AS (
  SELECT DISTINCT
    d_year,
    cc_state,
    cd_gender,
    cs_net_paid,
    ss_net_paid,
    ws_net_paid,
    cr_return_amount,
    sr_return_amt,
    inv_quantity_on_hand
  FROM base
),
aggregated AS (
  SELECT
    d_year,
    cc_state,
    cd_gender,
    SUM(cs_net_paid)          AS total_catalog_sales,
    SUM(ss_net_paid)          AS total_store_sales,
    SUM(ws_net_paid)          AS total_web_sales,
    SUM(cr_return_amount)    AS total_catalog_returns,
    SUM(sr_return_amt)       AS total_store_returns,
    SUM(inv_quantity_on_hand) AS total_inventory_qty
  FROM distinct_base
  GROUP BY CUBE (d_year, cc_state, cd_gender)
)
SELECT
  d_year,
  cc_state,
  cd_gender,
  total_catalog_sales,
  total_store_sales,
  total_web_sales,
  total_catalog_returns,
  total_store_returns,
  total_inventory_qty,
  CASE WHEN total_catalog_sales > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS rn_year
FROM aggregated
ORDER BY d_year, cc_state, cd_gender
LIMIT 100
