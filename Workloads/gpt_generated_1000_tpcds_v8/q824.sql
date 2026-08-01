WITH
  ws_base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_ship_mode_sk,
      ws.ws_web_page_sk,
      i.i_category,
      i.i_current_price,
      i.i_product_name,
      sm.sm_carrier,
      wp.wp_max_ad_count,
      wp.wp_rec_start_date
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND sm.sm_carrier = 'FEDEX'
      AND i.i_current_price > 50.00
      AND wp.wp_max_ad_count >= 1
  ),
  sr_base AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_return_amt_inc_tax,
      sr.sr_return_quantity,
      sr.sr_return_ship_cost,
      sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_return_ship_cost > 30.00
      AND sr.sr_net_loss > 150.00
  ),
  agg_rollup AS (
    SELECT
      i_category,
      sm_carrier,
      SUM(ws_ext_sales_price) AS sum_sales,
      SUM(ws_quantity) AS sum_qty,
      GROUPING(i_category) AS g_category,
      GROUPING(sm_carrier) AS g_carrier
    FROM ws_base
    GROUP BY GROUPING SETS (
      (i_category, sm_carrier),
      (i_category),
      (sm_carrier),
      ()
    )
  ),
  intersect_items AS (
    SELECT DISTINCT ws.ws_item_sk AS item_sk
    FROM ws_base ws
    WHERE ws.ws_ext_sales_price > 1000
    INTERSECT
    SELECT DISTINCT sr.sr_item_sk
    FROM sr_base sr
    WHERE sr.sr_return_amt_inc_tax > 500
  ),
  union_agg AS (
    SELECT category, SUM(total) AS sum_total, src
    FROM (
        SELECT i_category AS category, SUM(ws_ext_sales_price) AS total, 'sales' AS src
        FROM ws_base
        GROUP BY i_category
        UNION
        SELECT i_category AS category, SUM(sr_return_amt_inc_tax) AS total, 'returns' AS src
        FROM sr_base sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        GROUP BY i_category
    ) u
    GROUP BY category, src
  ),
  final AS (
    SELECT
      ws.ws_order_number,
      ws.ws_item_sk,
      ws.i_product_name,
      ws.i_category,
      ws.ws_ext_sales_price,
      ws.ws_quantity,
      ws.sm_carrier,
      ws.wp_max_ad_count,
      RANK() OVER (PARTITION BY ws.i_category ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank,
      (SELECT MAX(sr2.sr_return_amt_inc_tax)
         FROM store_returns sr2
         WHERE sr2.sr_item_sk = ws.ws_item_sk) AS max_return_amt,
      CASE
        WHEN ws.i_current_price > (
            SELECT AVG(i3.i_current_price)
            FROM item i3
            WHERE i3.i_brand_id = 1)
        THEN 'high'
        ELSE 'low'
      END AS price_category
    FROM ws_base ws
    WHERE ws.ws_item_sk IN (SELECT item_sk FROM intersect_items)
      AND ws.ws_ext_sales_price > (
          SELECT MAX(t.total_sales)
          FROM (
            SELECT SUM(ws_ext_sales_price) AS total_sales
            FROM ws_base
            GROUP BY ws_item_sk
          ) t
      )
      AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = ws.ws_item_sk
          AND sr.sr_net_loss > 200
      )
  )
SELECT
  final.ws_order_number,
  final.ws_item_sk,
  final.i_product_name,
  final.i_category,
  final.ws_ext_sales_price,
  final.ws_quantity,
  final.sm_carrier,
  final.wp_max_ad_count,
  final.sales_rank,
  final.max_return_amt,
  final.price_category
FROM final
ORDER BY final.sales_rank ASC, final.ws_ext_sales_price DESC
OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
