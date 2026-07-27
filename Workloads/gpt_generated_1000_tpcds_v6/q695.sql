WITH catalog_part AS (
  SELECT
    cs.cs_item_sk AS item_sk,
    i.i_product_name AS product_name,
    cs.cs_sold_date_sk AS sold_date_sk,
    td.t_hour AS hour_of_day,
    cs.cs_ext_sales_price AS sales_price,
    cs.cs_net_profit AS net_profit,
    cr.cr_return_amount AS return_amount,
    cr.cr_net_loss AS net_loss,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cs.cs_ext_sales_price DESC) AS rank_metric,
    'catalog' AS src
  FROM tpcds.catalog_sales cs
  JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
  JOIN tpcds.time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE cs.cs_ext_sales_price > 500
    AND cs.cs_net_profit > 0
    AND cr.cr_store_credit < 20
    AND td.t_hour BETWEEN 9 AND 17
    AND i.i_brand_id = 23
),
store_part AS (
  SELECT
    ss.ss_item_sk AS item_sk,
    i.i_product_name AS product_name,
    ss.ss_sold_date_sk AS sold_date_sk,
    td.t_hour AS hour_of_day,
    ss.ss_ext_sales_price AS sales_price,
    ss.ss_net_profit AS net_profit,
    sr.sr_return_amt AS return_amount,
    sr.sr_net_loss AS net_loss,
    RANK() OVER (PARTITION BY i.i_category ORDER BY ss.ss_ext_sales_price DESC) AS rank_metric,
    'store' AS src
  FROM tpcds.store_sales ss
  JOIN tpcds.item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
  JOIN tpcds.time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE ss.ss_ext_sales_price > 500
    AND ss.ss_net_profit > 0
    AND sr.sr_return_amt > 100
    AND td.t_hour BETWEEN 9 AND 17
    AND i.i_category_id = 5
)
SELECT *
FROM (
  SELECT * FROM catalog_part
  UNION ALL
  SELECT * FROM store_part
) combined
ORDER BY sales_price DESC
LIMIT 100
