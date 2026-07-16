WITH sales_agg AS (
    SELECT
        s.ss_sold_date_sk AS date_sk,
        s.ss_item_sk AS item_sk,
        s.ss_store_sk AS store_sk,
        SUM(s.ss_quantity) AS total_quantity_sold,
        SUM(s.ss_ext_sales_price) AS total_sales_amount,
        SUM(s.ss_net_profit) AS total_profit,
        AVG(s.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_transactions
    FROM store_sales s
    WHERE s.ss_sold_date_sk BETWEEN 2450815 AND 2451053
    GROUP BY s.ss_sold_date_sk, s.ss_item_sk, s.ss_store_sk
),
inventory_agg AS (
    SELECT
        i.inv_date_sk AS date_sk,
        i.inv_item_sk AS item_sk,
        i.inv_warehouse_sk AS warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory i
    WHERE i.inv_date_sk BETWEEN 2450815 AND 2451053
    GROUP BY i.inv_date_sk, i.inv_item_sk, i.inv_warehouse_sk
),
joined AS (
    SELECT
        sa.date_sk,
        sa.item_sk,
        sa.store_sk,
        ia.warehouse_sk,
        sa.total_quantity_sold,
        COALESCE(ia.total_inventory_qty, 0) AS total_inventory_qty,
        sa.total_sales_amount,
        sa.total_profit,
        sa.avg_discount,
        (COALESCE(ia.total_inventory_qty, 0) - sa.total_quantity_sold) AS projected_stock_remaining,
        CASE
            WHEN sa.total_quantity_sold > 100 THEN 'SM_AIR'
            WHEN sa.total_quantity_sold > 50 THEN 'SM_RAIL'
            ELSE 'SM_TRUCK'
        END AS ship_mode_id
    FROM sales_agg sa
    LEFT JOIN inventory_agg ia
        ON sa.date_sk = ia.date_sk
       AND sa.item_sk = ia.item_sk
)
SELECT
    j.date_sk,
    j.item_sk,
    j.store_sk,
    j.warehouse_sk,
    j.total_sales_amount,
    j.total_profit,
    j.projected_stock_remaining,
    r.r_reason_desc,
    sm.sm_carrier,
    RANK() OVER (PARTITION BY j.warehouse_sk ORDER BY j.projected_stock_remaining ASC) AS stockout_risk_rank
FROM joined j
JOIN reason r
    ON (j.projected_stock_remaining < 0 AND r.r_reason_desc = 'Parts missing')
     OR (j.projected_stock_remaining >= 0 AND r.r_reason_desc = 'Not the product that was ordred')
JOIN ship_mode sm
    ON sm.sm_ship_mode_id = j.ship_mode_id
WHERE j.projected_stock_remaining < 200
ORDER BY j.warehouse_sk, stockout_risk_rank
LIMIT 100
