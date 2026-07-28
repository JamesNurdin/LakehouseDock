WITH
  cs AS (
    SELECT
      cs_item_sk,
      cs_sold_date_sk,
      cs_call_center_sk,
      cs_warehouse_sk,
      SUM(cs_net_profit)      AS catalog_profit,
      SUM(cs_ext_sales_price) AS catalog_sales_amount
    FROM tpcds.catalog_sales
    GROUP BY cs_item_sk, cs_sold_date_sk, cs_call_center_sk, cs_warehouse_sk
  ),
  cr AS (
    SELECT
      cr_item_sk,
      cr_returned_date_sk,
      cr_call_center_sk,
      cr_warehouse_sk,
      SUM(cr_net_loss)     AS catalog_return_loss,
      SUM(cr_return_amount) AS catalog_return_amount
    FROM tpcds.catalog_returns
    GROUP BY cr_item_sk, cr_returned_date_sk, cr_call_center_sk, cr_warehouse_sk
  ),
  ws AS (
    SELECT
      ws_item_sk,
      ws_sold_date_sk,
      ws_warehouse_sk,
      SUM(ws_net_profit)      AS web_profit,
      SUM(ws_ext_sales_price) AS web_sales_amount
    FROM tpcds.web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk, ws_warehouse_sk
  ),
  sr AS (
    SELECT
      sr_item_sk,
      sr_returned_date_sk,
      SUM(sr_net_loss)    AS store_return_loss,
      SUM(sr_return_amt)  AS store_return_amount
    FROM tpcds.store_returns
    GROUP BY sr_item_sk, sr_returned_date_sk
  )
SELECT
  i1.i_category                AS item_category,
  d1.d_quarter_name            AS quarter,
  cc1.cc_name                  AS call_center_name,
  w1.w_warehouse_name          AS catalog_warehouse,
  w2.w_warehouse_name          AS return_warehouse,
  w3.w_warehouse_name          AS web_warehouse,
  SUM(cs.catalog_profit)       AS total_catalog_profit,
  SUM(ws.web_profit)           AS total_web_profit,
  SUM(sr.store_return_loss)    AS total_store_return_loss,
  SUM(cr.catalog_return_loss)  AS total_catalog_return_loss,
  CASE
    WHEN SUM(cs.catalog_profit) + SUM(ws.web_profit) - SUM(sr.store_return_loss) - SUM(cr.catalog_return_loss) > 0
      THEN 'Positive'
    ELSE 'Negative'
  END                           AS overall_profit_indicator
FROM cs
  JOIN tpcds.item i1               ON cs.cs_item_sk = i1.i_item_sk
  JOIN tpcds.date_dim d1           ON cs.cs_sold_date_sk = d1.d_date_sk
  JOIN tpcds.call_center cc1       ON cs.cs_call_center_sk = cc1.cc_call_center_sk
  JOIN tpcds.warehouse w1          ON cs.cs_warehouse_sk = w1.w_warehouse_sk
  JOIN cr                          ON cr.cr_item_sk = i1.i_item_sk
                                   AND cr.cr_returned_date_sk = d1.d_date_sk
  JOIN tpcds.call_center cc2       ON cr.cr_call_center_sk = cc2.cc_call_center_sk
  JOIN tpcds.warehouse w2          ON cr.cr_warehouse_sk = w2.w_warehouse_sk
  JOIN ws                          ON ws.ws_item_sk = i1.i_item_sk
                                   AND ws.ws_sold_date_sk = d1.d_date_sk
  JOIN tpcds.warehouse w3          ON ws.ws_warehouse_sk = w3.w_warehouse_sk
  JOIN sr                          ON sr.sr_item_sk = i1.i_item_sk
                                   AND sr.sr_returned_date_sk = d1.d_date_sk
GROUP BY
  i1.i_category,
  d1.d_quarter_name,
  cc1.cc_name,
  w1.w_warehouse_name,
  w2.w_warehouse_name,
  w3.w_warehouse_name
ORDER BY total_catalog_profit DESC
LIMIT 100
