WITH
  sr_agg AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_item_sk,
      sr.sr_cdemo_sk,
      SUM(sr.sr_return_quantity) AS total_return_qty,
      SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    WHERE sr.sr_return_ship_cost > 100.00
      AND sr.sr_return_quantity > 0
    GROUP BY sr.sr_store_sk, sr.sr_item_sk, sr.sr_cdemo_sk
  ),
  cr_agg AS (
    SELECT
      cr.cr_item_sk,
      SUM(cr.cr_return_amount) AS total_catalog_return_amt,
      SUM(cr.cr_net_loss) AS total_catalog_net_loss
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 20.00
    GROUP BY cr.cr_item_sk
  )
SELECT
  s.s_state,
  i.i_category,
  cd_sr.cd_gender,
  brand_avg.brand_avg_price,
  SUM(sr_agg.total_return_qty)            AS sum_return_qty,
  SUM(sr_agg.total_return_amt)            AS sum_return_amt,
  SUM(cr_agg.total_catalog_return_amt)    AS sum_catalog_return_amt,
  SUM(ws.ws_net_profit)                   AS sum_net_profit,
  COUNT(DISTINCT ws.ws_order_number)      AS distinct_orders
FROM sr_agg
JOIN store s ON sr_agg.sr_store_sk = s.s_store_sk
JOIN item i ON sr_agg.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd_sr ON sr_agg.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN cr_agg ON i.i_item_sk = cr_agg.cr_item_sk
JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                        AND wr.wr_order_number = ws.ws_order_number
CROSS JOIN LATERAL (
  SELECT AVG(i2.i_current_price) AS brand_avg_price
  FROM item i2
  WHERE i2.i_brand_id = i.i_brand_id
) AS brand_avg
WHERE s.s_state = 'CA'
  AND i.i_current_price > 50.00
  AND ws.ws_sold_date_sk = 2451911
  AND (wr.wr_return_quantity = 1 OR wr.wr_return_quantity IS NULL)
  AND NOT EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
      )
GROUP BY s.s_state, i.i_category, cd_sr.cd_gender, brand_avg.brand_avg_price
UNION DISTINCT
SELECT
  s.s_state,
  i.i_category,
  cd_sr.cd_gender,
  brand_avg.brand_avg_price,
  SUM(sr_agg.total_return_qty)            AS sum_return_qty,
  SUM(sr_agg.total_return_amt)            AS sum_return_amt,
  SUM(cr_agg.total_catalog_return_amt)    AS sum_catalog_return_amt,
  SUM(ws.ws_net_profit)                   AS sum_net_profit,
  COUNT(DISTINCT ws.ws_order_number)      AS distinct_orders
FROM sr_agg
JOIN store s ON sr_agg.sr_store_sk = s.s_store_sk
JOIN item i ON sr_agg.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd_sr ON sr_agg.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN cr_agg ON i.i_item_sk = cr_agg.cr_item_sk
JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                        AND wr.wr_order_number = ws.ws_order_number
CROSS JOIN LATERAL (
  SELECT AVG(i2.i_current_price) AS brand_avg_price
  FROM item i2
  WHERE i2.i_brand_id = i.i_brand_id
) AS brand_avg
WHERE s.s_gmt_offset BETWEEN -8.00 AND -5.00
  AND i.i_color = 'Red'
  AND i.i_rec_start_date = DATE '2021-01-01'
  AND ws.ws_sold_date_sk = 2451912
  AND (wr.wr_return_quantity = 1 OR wr.wr_return_quantity IS NULL)
  AND NOT EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
      )
GROUP BY s.s_state, i.i_category, cd_sr.cd_gender, brand_avg.brand_avg_price
ORDER BY sum_net_profit DESC
LIMIT 100
