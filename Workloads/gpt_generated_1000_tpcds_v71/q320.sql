/*
  Goal: Analyze return and sales performance by catalog page and warehouse for California home pages, 
  applying several filters, excluding returns that have a matching web sale order, and ranking the 
  results by total return amount. Subtotals are produced using ROLLUP.
*/
WITH filtered_data AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        w.w_warehouse_name,
        w.w_state,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        ws.ws_ext_sales_price,
        ws.ws_ext_wholesale_cost,
        ws.ws_quantity,
        ws.ws_net_profit,
        wp.wp_type
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cp.cp_catalog_number IN (5, 14)
      AND cr.cr_return_amount > 50
      AND cr.cr_reversed_charge < 200
      AND ws.ws_ext_wholesale_cost > 1000
      AND wp.wp_type = 'Home'
      AND w.w_state = 'CA'
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_order_number = cr.cr_order_number
      )
),
aggregated AS (
    SELECT
        cp_catalog_page_id,
        w_warehouse_name,
        SUM(cr_return_amount)          AS total_return_amount,
        SUM(ws_ext_sales_price)        AS total_sales_amount,
        COUNT(DISTINCT cr_return_quantity) AS distinct_return_qty,
        COUNT(DISTINCT ws_quantity)        AS distinct_sales_qty
    FROM filtered_data
    GROUP BY ROLLUP (cp_catalog_page_id, w_warehouse_name)
)
SELECT
    cp_catalog_page_id,
    w_warehouse_name,
    total_return_amount,
    total_sales_amount,
    distinct_return_qty,
    distinct_sales_qty,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM aggregated
ORDER BY total_return_amount DESC NULLS LAST
LIMIT 100
