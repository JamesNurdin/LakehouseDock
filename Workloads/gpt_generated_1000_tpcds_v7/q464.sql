WITH joined_data AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        wh.w_warehouse_name,
        sm.sm_ship_mode_id,
        cr.cr_return_amount,
        ws.ws_ext_sales_price,
        inv.inv_quantity_on_hand,
        cr.cr_store_credit,
        sm.sm_contract,
        wh.w_state,
        site.web_county,
        p.p_promo_name
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    WHERE sm.sm_contract IN ('OrDuVy2H', 'Xjy3ZPuiDjzHlRx14Z3')
      AND wh.w_state = 'CA'
      AND site.web_county = 'Jefferson Davis Parish'
      AND p.p_promo_name LIKE '%Discount%'
      AND cr.cr_store_credit > 100
),
agg1 AS (
    SELECT
        w_warehouse_name AS warehouse_name,
        sm_ship_mode_id AS ship_mode_id,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_ext_sales_price) AS total_sales_amount,
        SUM(inv_quantity_on_hand) AS total_inventory_qty,
        CASE WHEN SUM(cr_return_amount) > SUM(ws_ext_sales_price)
            THEN 'Loss' ELSE 'Profit' END AS profit_indicator
    FROM joined_data
    GROUP BY w_warehouse_name, sm_ship_mode_id
)
SELECT
    warehouse_name,
    ship_mode_id,
    total_return_amount,
    total_sales_amount,
    total_inventory_qty,
    profit_indicator,
    total_return_amount / NULLIF(total_inventory_qty, 0) AS return_per_inventory
FROM agg1
WHERE total_sales_amount > 1000
ORDER BY total_return_amount DESC
