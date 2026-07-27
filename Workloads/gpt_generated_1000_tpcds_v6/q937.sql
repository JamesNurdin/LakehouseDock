WITH base AS (
    SELECT
        i.i_brand,
        i.i_category,
        sm.sm_ship_mode_id,
        w.w_state,
        cp.cp_department,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        CASE WHEN cr.cr_return_amount > 0 THEN 1 ELSE 0 END AS has_refund
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                     AND ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE sm.sm_ship_mode_id IN ('AAAAAAAAIAAAAAAA','AAAAAAAABBAAAAAA')
      AND cp.cp_department = 'Electronics'
      AND i.i_brand = 'Brand#12'
      AND w.w_state = 'CA'
      AND ws.ws_sold_date_sk BETWEEN 2450905 AND 2451085
),
agg AS (
    SELECT
        i_brand,
        sm_ship_mode_id,
        w_state,
        cp_department,
        SUM(cr_return_amount)            AS total_return_amount,
        SUM(cr_return_quantity)          AS total_return_qty,
        SUM(ws_ext_sales_price)          AS total_sales,
        SUM(ws_net_profit)               AS total_profit,
        SUM(has_refund)                  AS refund_count
    FROM base
    GROUP BY GROUPING SETS (
        (i_brand, sm_ship_mode_id, w_state, cp_department),
        (i_brand, sm_ship_mode_id, w_state),
        (i_brand, sm_ship_mode_id),
        (i_brand, w_state),
        (sm_ship_mode_id, w_state),
        (i_brand),
        (sm_ship_mode_id),
        (w_state),
        ()
    )
)
SELECT
    i_brand,
    sm_ship_mode_id,
    w_state,
    cp_department,
    total_return_amount,
    total_return_qty,
    total_sales,
    total_profit,
    refund_count,
    CASE WHEN total_return_qty = 0 THEN 0 ELSE total_return_amount / total_return_qty END AS avg_return_per_qty,
    total_profit / NULLIF(total_sales, 0) AS profit_margin
FROM agg
WHERE (total_sales > 1000 OR total_profit > 100)
  AND (refund_count > 0 OR total_return_qty > 5)
  AND (CASE WHEN total_return_qty = 0 THEN 0 ELSE total_return_amount / total_return_qty END) > 10
  AND EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_id = agg.sm_ship_mode_id
          AND sm2.sm_contract LIKE 'uukTktPY%'
    )
ORDER BY total_profit DESC
LIMIT 100
