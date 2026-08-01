WITH
  sales_agg AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      i.i_category,
      i.i_brand_id,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS orders,
      MAX(ws.ws_quantity) AS max_quantity,
      AVG(ws.ws_sales_price) AS avg_price,
      (SELECT AVG(i2.i_current_price)
         FROM tpcds.item i2
        WHERE i2.i_brand_id = i.i_brand_id) AS avg_price_by_brand,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM tpcds.web_sales ws
    JOIN tpcds.item i               ON ws.ws_item_sk      = i.i_item_sk
    JOIN tpcds.promotion p          ON ws.ws_promo_sk     = p.p_promo_sk
    JOIN tpcds.ship_mode sm         ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w          ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_page wp          ON ws.ws_web_page_sk  = wp.wp_web_page_sk
    JOIN tpcds.customer c           ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451100
      AND i.i_current_price > 20
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND w.w_city = 'Los Angeles'
      AND EXISTS (
            SELECT 1
              FROM tpcds.store_returns sr
             WHERE sr.sr_item_sk = ws.ws_item_sk
               AND sr.sr_return_quantity > 0)
    GROUP BY i.i_item_id, i.i_product_name, i.i_category, i.i_brand_id
  ),

  returns_agg AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      i.i_category,
      i.i_brand_id,
      SUM(cr.cr_return_amount) AS total_returns,
      COUNT(DISTINCT cr.cr_order_number) AS return_orders,
      MIN(cr.cr_return_quantity) AS min_return_qty,
      MAX(cr.cr_return_quantity) AS max_return_qty,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cr.cr_return_amount) DESC) AS return_rank
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i               ON cr.cr_item_sk          = i.i_item_sk
    JOIN tpcds.call_center cc       ON cr.cr_call_center_sk   = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp      ON cr.cr_catalog_page_sk  = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm         ON cr.cr_ship_mode_sk     = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w          ON cr.cr_warehouse_sk     = w.w_warehouse_sk
    JOIN tpcds.reason r             ON cr.cr_reason_sk        = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2451100
      AND i.i_current_price BETWEEN 30 AND 100
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'STANDARD'
      AND sm.sm_type = 'AIR'
    GROUP BY i.i_item_id, i.i_product_name, i.i_category, i.i_brand_id
  ),

  full_combined AS (
    SELECT
      s.i_item_id,
      s.i_product_name,
      s.i_category,
      s.i_brand_id,
      s.total_sales,
      s.orders,
      s.max_quantity,
      s.avg_price,
      s.avg_price_by_brand,
      s.sales_rank,
      r.total_returns,
      r.return_orders,
      r.min_return_qty,
      r.max_return_qty,
      r.return_rank
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
      ON s.i_item_id = r.i_item_id
  ),

  high_store_returns AS (
    SELECT i.i_item_id
    FROM tpcds.store_returns sr
    JOIN tpcds.item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_return_quantity > 5
  ),

  filtered_combined AS (
    SELECT fc.*
    FROM full_combined fc
    WHERE NOT EXISTS (
            SELECT 1
              FROM high_store_returns hsr
             WHERE hsr.i_item_id = fc.i_item_id)
  ),

  unioned AS (
    SELECT * FROM filtered_combined
    UNION DISTINCT
    SELECT * FROM filtered_combined WHERE total_returns IS NULL
  ),

  final AS (
    SELECT
      fu.i_item_id,
      fu.i_product_name,
      fu.i_category,
      fu.total_sales,
      fu.total_returns,
      fu.sales_rank,
      fu.return_rank,
      fu.avg_price,
      fu.avg_price_by_brand,
      rd.r_reason_desc
    FROM unioned fu
    LEFT JOIN tpcds.item it
      ON fu.i_item_id = it.i_item_id
    LEFT JOIN LATERAL (
          SELECT r.r_reason_desc
          FROM tpcds.store_returns sr
          JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
          WHERE sr.sr_item_sk = it.i_item_sk
          ORDER BY sr.sr_returned_date_sk DESC
          LIMIT 1
        ) rd ON TRUE
  )
SELECT
  f.i_item_id,
  f.i_product_name,
  f.i_category,
  f.total_sales,
  f.total_returns,
  f.sales_rank,
  f.return_rank,
  f.avg_price,
  f.avg_price_by_brand,
  f.r_reason_desc
FROM final f
WHERE f.total_sales > 1000
  AND (f.total_returns IS NULL OR f.total_returns < 500)
  AND f.i_category IN ('Sports', 'Books')
  AND f.sales_rank <= 10
  AND EXISTS (
        SELECT 1
          FROM tpcds.web_returns wr
          JOIN tpcds.item i2 ON wr.wr_item_sk = i2.i_item_sk
         WHERE i2.i_item_id = f.i_item_id
           AND wr.wr_return_quantity > 0)
ORDER BY f.total_sales DESC
LIMIT 100
