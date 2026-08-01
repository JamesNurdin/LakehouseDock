-- Goal: Compare sales performance across store and web channels per item, rank items, and enrich with catalog information while accounting for returns, using window functions and multiple joins.
WITH
  store_agg AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      s.s_store_sk,
      s.s_store_id   AS location_id,
      d.d_year,
      SUM(ss.ss_ext_sales_price)                     AS sales_amount,
      SUM(ss.ss_net_profit)                          AS profit,
      COUNT(*)                                        AS txn_cnt,
      ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t          ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i              ON ss.ss_item_sk = i.i_item_sk
    JOIN store s             ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c          ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND i.i_manufact_id IN (260, 294)
      AND d.d_year BETWEEN 1998 AND 2000
      AND t.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, s.s_store_sk, s.s_store_id, d.d_year
    HAVING SUM(ss.ss_ext_sales_price) > 500
  ),

  web_agg AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      CAST(NULL AS INTEGER)                         AS s_store_sk,
      wp.wp_web_page_id                             AS location_id,
      d.d_year,
      SUM(ws.ws_ext_sales_price)                     AS sales_amount,
      SUM(ws.ws_net_profit)                          AS profit,
      COUNT(*)                                        AS txn_cnt,
      ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
      SUM(COALESCE(wr.wr_return_quantity, 0))        AS return_qty
    FROM web_sales ws
    JOIN date_dim d          ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t          ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i              ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp         ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c          ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND i.i_manufact_id IN (260, 294)
      AND d.d_year BETWEEN 1998 AND 2000
      AND t.t_hour BETWEEN 9 AND 17
      AND wp.wp_type = 'home'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, wp.wp_web_page_id, d.d_year
    HAVING SUM(ws.ws_ext_sales_price) > 500
  ),

  combined AS (
    SELECT
      'store' AS channel,
      i_item_sk,
      i_item_id,
      i_product_name,
      location_id,
      s_store_sk,
      d_year,
      sales_amount,
      profit,
      txn_cnt,
      sales_rank,
      CAST(NULL AS BIGINT) AS return_qty
    FROM store_agg
    UNION ALL
    SELECT
      'web' AS channel,
      i_item_sk,
      i_item_id,
      i_product_name,
      location_id,
      s_store_sk,
      d_year,
      sales_amount,
      profit,
      txn_cnt,
      sales_rank,
      return_qty
    FROM web_agg
  )

SELECT
  c.channel,
  c.i_item_id,
  c.i_product_name,
  c.location_id,
  c.d_year,
  c.sales_amount,
  c.profit,
  c.txn_cnt,
  c.sales_rank,
  cs.cs_order_number,
  cp.cp_catalog_number,
  COALESCE(sr.sr_return_quantity, 0)                     AS store_return_qty,
  c.return_qty                                            AS web_return_qty,
  RANK() OVER (PARTITION BY c.channel ORDER BY c.sales_amount DESC) AS channel_sales_rank
FROM combined c
LEFT JOIN catalog_sales cs
  ON cs.cs_item_sk = c.i_item_sk
LEFT JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = c.i_item_sk AND sr.sr_store_sk = c.s_store_sk
WHERE c.sales_amount > (
        SELECT AVG(sales_amount)
        FROM store_agg
      )
  AND c.d_year = 1999
  AND c.channel = 'store'
  AND c.sales_rank <= 10
  AND cp.cp_type = 'promo'
ORDER BY c.sales_amount DESC
LIMIT 100
