WITH cs_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS c_customer_sk,
        hd.hd_demo_sk AS hd_demo_sk,
        w_cs.w_warehouse_sk AS w_warehouse_sk,
        w_cs.w_state AS w_state,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_promo_sk) AS distinct_promos_cs
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w_cs
        ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
        cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
        AND cp.cp_department = 'Electronics'
        AND p_cs.p_discount_active = 'Y'
        AND sm_cs.sm_type = 'AIR'
        AND w_cs.w_state = 'CA'
        AND EXISTS (
            SELECT 1
            FROM inventory i2
            WHERE i2.inv_warehouse_sk = w_cs.w_warehouse_sk
              AND i2.inv_quantity_on_hand > 500
        )
    GROUP BY
        cs.cs_bill_customer_sk,
        hd.hd_demo_sk,
        w_cs.w_warehouse_sk,
        w_cs.w_state
),
ws_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS c_customer_sk,
        hd_ws.hd_demo_sk AS hd_demo_sk,
        w_ws.w_warehouse_sk AS w_warehouse_sk,
        w_ws.w_state AS w_state,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_promo_sk) AS distinct_promos_ws
    FROM web_sales ws
    JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN customer c_ws
        ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    JOIN household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
        AND p_ws.p_discount_active = 'Y'
        AND sm_ws.sm_type = 'AIR'
        AND w_ws.w_state = 'CA'
    GROUP BY
        ws.ws_bill_customer_sk,
        hd_ws.hd_demo_sk,
        w_ws.w_warehouse_sk,
        w_ws.w_state
),
inv_agg AS (
    SELECT
        i.inv_warehouse_sk AS w_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory i
    GROUP BY i.inv_warehouse_sk
),
combined AS (
    SELECT
        cs.c_customer_sk,
        cs.hd_demo_sk,
        cs.w_state,
        cs.total_catalog_sales,
        ws.total_web_sales,
        inv.total_inventory_qty,
        cs.distinct_promos_cs,
        ws.distinct_promos_ws
    FROM cs_agg cs
    JOIN ws_agg ws
        ON cs.c_customer_sk = ws.c_customer_sk
        AND cs.w_state = ws.w_state
    JOIN inv_agg inv
        ON cs.w_warehouse_sk = inv.w_warehouse_sk
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_customer_sk = cs.c_customer_sk
          AND sr.sr_hdemo_sk = cs.hd_demo_sk
          AND r.r_reason_desc = 'Damaged'
    )
)
SELECT
    w_state,
    COUNT(*) AS num_customers,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_inventory_qty) AS avg_inventory_qty,
    AVG(distinct_promos_cs + distinct_promos_ws) AS avg_total_distinct_promos
FROM combined
GROUP BY w_state
HAVING AVG(total_catalog_sales) > 1000
ORDER BY avg_catalog_sales DESC
LIMIT 100
