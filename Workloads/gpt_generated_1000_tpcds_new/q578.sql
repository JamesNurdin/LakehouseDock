WITH
  /* Sample a fraction of store_sales */
  store_sales_sampled AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),

  /* Full outer join store_sales with store_returns */
  store_full AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      i.i_brand_id,
      i.i_category,
      c.c_customer_sk,
      ca.ca_gmt_offset,
      t.t_hour
    FROM store_sales_sampled ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv
      ON ss.ss_item_sk = inv.inv_item_sk
    WHERE i.i_manufact_id IN (625, 630)
      AND ca.ca_gmt_offset = -5.00
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_ext_sales_price > 1000
  ),

  /* Join catalog_sales with its returns and other dimensions */
  catalog_join AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      i.i_brand_id,
      i.i_category,
      c.c_customer_sk,
      ca.ca_gmt_offset,
      t.t_hour
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv
      ON cs.cs_item_sk = inv.inv_item_sk
    WHERE i.i_brand_id = 260
      AND ca.ca_gmt_offset = -7.00
      AND t.t_hour = 12
      AND cs.cs_ext_sales_price > 2000
  ),

  /* Join web_sales with its dimensions */
  web_join AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      i.i_brand_id,
      i.i_category,
      c.c_customer_sk,
      ca.ca_gmt_offset,
      t.t_hour,
      ws.ws_web_site_sk
    FROM web_sales ws
    LEFT JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv
      ON ws.ws_item_sk = inv.inv_item_sk
    LEFT JOIN web_site w
      ON ws.ws_web_site_sk = w.web_site_sk
    WHERE i.i_category = 'Sports'
      AND ca.ca_gmt_offset = -8.00
      AND t.t_hour BETWEEN 14 AND 20
      AND ws.ws_ext_sales_price > 1500
  ),

  /* Union the three channel sources */
  union_raw AS (
    SELECT
      ss_item_sk AS item_sk,
      ss_ext_sales_price AS sales_amount,
      ss_net_profit AS profit,
      'store' AS channel,
      ARRAY[ss_ext_sales_price, COALESCE(sr_return_amt, 0)] AS metrics
    FROM store_full
    UNION DISTINCT
    SELECT
      cs_item_sk,
      cs_ext_sales_price,
      cs_net_profit,
      'catalog' AS channel,
      ARRAY[cs_ext_sales_price, COALESCE(cr_return_amount, 0)] AS metrics
    FROM catalog_join
    UNION DISTINCT
    SELECT
      ws_item_sk,
      ws_ext_sales_price,
      ws_net_profit,
      'web' AS channel,
      ARRAY[ws_ext_sales_price, 0] AS metrics
    FROM web_join
  ),

  /* Expand the metrics array */
  unnested AS (
    SELECT
      item_sk,
      channel,
      sales_amount,
      profit,
      m AS metric_value,
      CASE WHEN profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag
    FROM union_raw
    CROSS JOIN UNNEST(metrics) AS t(m)
  )

SELECT
  i.i_item_id,
  i.i_product_name,
  u.channel,
  COUNT(*) AS transaction_cnt,
  SUM(u.sales_amount) AS total_sales,
  AVG(u.profit) AS avg_profit,
  MIN(u.sales_amount) AS min_sale,
  MAX(u.sales_amount) AS max_sale,
  SUM(CASE WHEN u.profit_flag = 'Positive' THEN u.sales_amount ELSE 0 END) AS positive_sales,
  SUM(CASE WHEN u.profit_flag = 'Negative' THEN u.sales_amount ELSE 0 END) AS negative_sales
FROM unnested u
JOIN item i
  ON u.item_sk = i.i_item_sk
GROUP BY
  i.i_item_id,
  i.i_product_name,
  u.channel
ORDER BY total_sales DESC
LIMIT 100
