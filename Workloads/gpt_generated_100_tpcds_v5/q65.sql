WITH sub1 AS (
  SELECT
    d_sales.d_year AS year,
    d_sales.d_month_seq AS month_seq,
    cs.cs_ext_sales_price AS catalog_ext_sales,
    cs.cs_net_profit AS catalog_profit,
    ss.ss_ext_sales_price AS store_ext_sales,
    ss.ss_net_profit AS store_profit,
    sr.sr_net_loss AS net_loss,
    cs.cs_order_number AS order_num,
    ss.ss_ticket_number AS ticket_num
  FROM catalog_sales cs
  JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
  JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = cs.cs_item_sk
   AND ss.ss_ticket_number = cs.cs_order_number
  JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
  WHERE cs.cs_ship_hdemo_sk IN (722, 5664)
    AND cs.cs_ext_list_price > 1000
    AND d_sales.d_date BETWEEN DATE '1900-01-01' AND DATE '1900-01-31'
    AND ss.ss_quantity BETWEEN 1 AND 5
    AND sr.sr_net_loss > 500
    AND d_return.d_year = 1900
),
sub2 AS (
  SELECT
    d_sales.d_year AS year,
    d_sales.d_month_seq AS month_seq,
    cs.cs_ext_sales_price AS catalog_ext_sales,
    cs.cs_net_profit AS catalog_profit,
    ss.ss_ext_sales_price AS store_ext_sales,
    ss.ss_net_profit AS store_profit,
    sr.sr_net_loss AS net_loss,
    cs.cs_order_number AS order_num,
    ss.ss_ticket_number AS ticket_num
  FROM catalog_sales cs
  JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
  JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = cs.cs_item_sk
   AND ss.ss_ticket_number = cs.cs_order_number
  JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
  WHERE cs.cs_ship_hdemo_sk = 6189
    AND cs.cs_ext_list_price < 2000
    AND d_sales.d_month_seq = 14
    AND ss.ss_quantity > 2
    AND sr.sr_fee BETWEEN 30 AND 80
    AND d_return.d_month_seq = 9
)
SELECT
  year,
  month_seq,
  SUM(catalog_ext_sales) AS sum_catalog_sales,
  SUM(store_ext_sales) AS sum_store_sales,
  SUM(catalog_profit) AS sum_catalog_profit,
  SUM(store_profit) AS sum_store_profit,
  SUM(net_loss) AS sum_net_loss,
  COUNT(DISTINCT order_num) AS cnt_orders,
  COUNT(DISTINCT ticket_num) AS cnt_tickets
FROM (
  SELECT * FROM sub1
  UNION ALL
  SELECT * FROM sub2
) u
GROUP BY GROUPING SETS (
  (year, month_seq),
  (year),
  ()
)
ORDER BY year ASC, month_seq ASC
LIMIT 100
