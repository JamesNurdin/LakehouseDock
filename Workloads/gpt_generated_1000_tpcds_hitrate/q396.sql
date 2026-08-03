WITH base AS (
    SELECT
        cr.cr_return_amount,
        wr.wr_return_amt,
        cr.cr_return_quantity,
        sm.sm_ship_mode_id,
        sm.sm_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        w.w_warehouse_id,
        -- LATERAL subquery that uses the current warehouse key
        l.warehouse_qty
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    -- LATERAL subquery referencing the current warehouse (w)
    CROSS JOIN LATERAL (
        SELECT SUM(cr2.cr_return_quantity) AS warehouse_qty
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
    ) AS l
    JOIN web_sales ws
        ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    WHERE hd.hd_buy_potential IN ('1001-5000', '5001-10000')
      AND ib.ib_upper_bound <= 200000
      AND sm.sm_type IN ('AIR', 'RAIL')
),
agg_air AS (
    SELECT
        sm_ship_mode_id,
        ib_lower_bound,
        ib_upper_bound,
        SUM(cr_return_amount + wr_return_amt) AS total_return_amount,
        COUNT(*) AS cnt,
        SUM(warehouse_qty) AS total_warehouse_qty
    FROM base
    WHERE sm_type = 'AIR'
    GROUP BY sm_ship_mode_id, ib_lower_bound, ib_upper_bound
),
agg_non_air AS (
    SELECT
        sm_ship_mode_id,
        ib_lower_bound,
        ib_upper_bound,
        SUM(cr_return_amount + wr_return_amt) AS total_return_amount,
        COUNT(*) AS cnt,
        SUM(warehouse_qty) AS total_warehouse_qty
    FROM base
    WHERE sm_type <> 'AIR'
    GROUP BY sm_ship_mode_id, ib_lower_bound, ib_upper_bound
),
unioned AS (
    SELECT sm_ship_mode_id,
           ib_lower_bound,
           ib_upper_bound,
           total_return_amount,
           cnt,
           total_warehouse_qty
    FROM agg_air
    UNION DISTINCT
    SELECT sm_ship_mode_id,
           ib_lower_bound,
           ib_upper_bound,
           total_return_amount,
           cnt,
           total_warehouse_qty
    FROM agg_non_air
)
SELECT
    sm_ship_mode_id,
    ib_lower_bound,
    ib_upper_bound,
    total_return_amount,
    cnt,
    total_warehouse_qty,
    -- Example CASE expression: flag high‑loss ship modes
    CASE WHEN total_return_amount > 50000 THEN 'HIGH' ELSE 'NORMAL' END AS loss_category,
    total_return_amount / NULLIF(cnt, 0) AS avg_return_amount
FROM unioned
WHERE total_warehouse_qty > 1000
ORDER BY total_return_amount DESC
