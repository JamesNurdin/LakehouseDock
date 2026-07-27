WITH
  store_data AS (
    SELECT
      ss.ss_sold_date_sk AS ss_sold_date_sk,
      ss.ss_ticket_number AS ss_ticket_number,
      ss.ss_item_sk AS ss_item_sk,
      ss.ss_quantity AS ss_quantity,
      ss.ss_ext_sales_price AS ss_ext_sales_price,
      ss.ss_net_profit AS ss_net_profit,
      sr.sr_return_quantity AS sr_return_quantity,
      sr.sr_net_loss AS sr_net_loss,
      p1.p_promo_id AS p_promo_id,
      p1.p_cost AS p_cost,
      td1.t_hour AS t_hour,
      td1.t_time AS t_time,
      td1.t_time_sk AS t_time_sk,
      td2.t_hour AS ret_t_hour,
      td2.t_time AS ret_t_time,
      td2.t_time_sk AS ret_t_time_sk
    FROM store_sales ss
    INNER JOIN time_dim td1
      ON ss.ss_sold_time_sk = td1.t_time_sk
    INNER JOIN promotion p1
      ON ss.ss_promo_sk = p1.p_promo_sk
    LEFT JOIN store_returns sr
      ON ss.ss_item_sk = sr.sr_item_sk
     AND ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN time_dim td2
      ON sr.sr_return_time_sk = td2.t_time_sk
    WHERE p1.p_channel_press = 'N'
      AND p1.p_cost > 500
      AND td1.t_hour BETWEEN 8 AND 12
      AND EXISTS (SELECT 1 FROM call_center cc3 WHERE cc3.cc_state = 'CA')
  ),
  catalog_data AS (
    SELECT
      cs.cs_sold_date_sk AS cs_sold_date_sk,
      cs.cs_order_number AS cs_order_number,
      cs.cs_item_sk AS cs_item_sk,
      cs.cs_quantity AS cs_quantity,
      cs.cs_ext_sales_price AS cs_ext_sales_price,
      cs.cs_net_profit AS cs_net_profit,
      cr.cr_return_quantity AS cr_return_quantity,
      cr.cr_net_loss AS cr_net_loss,
      p2.p_promo_id AS p_promo_id,
      p2.p_cost AS p_cost,
      td3.t_hour AS t_hour,
      td3.t_time AS t_time,
      td3.t_time_sk AS t_time_sk,
      cc2.cc_state AS cc_state,
      cp.cp_department AS cp_department
    FROM catalog_sales cs
    INNER JOIN time_dim td3
      ON cs.cs_sold_time_sk = td3.t_time_sk
    INNER JOIN promotion p2
      ON cs.cs_promo_sk = p2.p_promo_sk
    INNER JOIN call_center cc2
      ON cs.cs_call_center_sk = cc2.cc_call_center_sk
    INNER JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
      ON cs.cs_item_sk = cr.cr_item_sk
     AND cs.cs_order_number = cr.cr_order_number
    LEFT JOIN time_dim td4
      ON cr.cr_returned_time_sk = td4.t_time_sk
    WHERE p2.p_channel_press = 'N'
      AND p2.p_cost > 500
      AND td3.t_hour BETWEEN 8 AND 12
      AND cc2.cc_state = 'CA'
      AND cc2.cc_rec_start_date >= DATE '2000-01-01'
  ),
  combined AS (
    SELECT
      ss_sold_date_sk AS date_sk,
      ss_ticket_number AS ticket_id,
      ss_item_sk AS item_sk,
      ss_quantity AS quantity,
      ss_ext_sales_price AS sales_price,
      ss_net_profit AS net_profit,
      sr_return_quantity AS return_qty,
      sr_net_loss AS net_loss,
      p_promo_id,
      p_cost,
      t_hour,
      t_time,
      NULL AS department,
      'store' AS sales_channel
    FROM store_data
    UNION ALL
    SELECT
      cs_sold_date_sk AS date_sk,
      cs_order_number AS ticket_id,
      cs_item_sk AS item_sk,
      cs_quantity AS quantity,
      cs_ext_sales_price AS sales_price,
      cs_net_profit AS net_profit,
      cr_return_quantity AS return_qty,
      cr_net_loss AS net_loss,
      p_promo_id,
      p_cost,
      t_hour,
      t_time,
      cp_department AS department,
      'catalog' AS sales_channel
    FROM catalog_data
  ),
  aggregated AS (
    SELECT
      date_sk,
      sales_channel,
      department,
      SUM(sales_price) AS total_sales,
      SUM(net_profit) AS total_profit,
      SUM(CASE WHEN p_cost > 1000 THEN sales_price ELSE 0 END) AS high_cost_sales,
      COUNT(*) AS txn_count
    FROM combined
    GROUP BY date_sk, sales_channel, department
    HAVING SUM(sales_price) > 1000
  ),
  ranked AS (
    SELECT
      date_sk,
      sales_channel,
      department,
      total_sales,
      total_profit,
      high_cost_sales,
      txn_count,
      RANK() OVER (PARTITION BY sales_channel ORDER BY total_sales DESC) AS sales_rank,
      (SELECT AVG(total_sales) FROM aggregated) AS avg_total_sales
    FROM aggregated
  )
SELECT
  date_sk,
  sales_channel,
  department,
  total_sales,
  total_profit,
  high_cost_sales,
  txn_count,
  sales_rank,
  avg_total_sales
FROM ranked
WHERE sales_rank <= 10
ORDER BY sales_channel, sales_rank
LIMIT 100
