WITH sales_info AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_list_price,
        w_cs.w_warehouse_name,
        w_cs.w_warehouse_sk,
        p_cs.p_promo_sk,
        p_cs.p_promo_name,
        hd_bill.hd_demo_sk      AS hd_bill_demo_sk,
        hd_bill.hd_income_band_sk,
        ib_bill.ib_lower_bound,
        ib_bill.ib_upper_bound
    FROM catalog_sales cs
    JOIN warehouse w_cs
        ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib_bill
        ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
),
store_info AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_list_price,
        hd_ss.hd_demo_sk,
        p_ss.p_promo_sk
    FROM store_sales ss
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
),
inventory_info AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        w_inv.w_warehouse_name
    FROM inventory inv
    JOIN warehouse w_inv
        ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    GROUP BY inv.inv_warehouse_sk, w_inv.w_warehouse_name
),
sales_agg AS (
    SELECT
        si.w_warehouse_name,
        SUM(si.cs_net_paid) AS total_catalog_net_paid,
        SUM(sti.ss_net_paid) AS total_store_net_paid,
        SUM(si.cs_net_paid) + SUM(sti.ss_net_paid) AS total_net_paid
    FROM sales_info si
    LEFT JOIN store_info sti
        ON sti.p_promo_sk = si.p_promo_sk
    GROUP BY si.w_warehouse_name
)
SELECT
    sa.w_warehouse_name,
    'sales'      AS metric_category,
    sa.total_net_paid AS amount,
    ROW_NUMBER() OVER (PARTITION BY sa.w_warehouse_name ORDER BY sa.total_net_paid DESC) AS rank,
    (SELECT AVG(ib.ib_lower_bound) FROM income_band ib) AS avg_income_lower_bound
FROM sales_agg sa

UNION ALL

SELECT
    ii.w_warehouse_name,
    'inventory' AS metric_category,
    ii.total_quantity AS amount,
    CAST(NULL AS BIGINT) AS rank,
    (SELECT AVG(ib.ib_lower_bound) FROM income_band ib) AS avg_income_lower_bound
FROM inventory_info ii

ORDER BY amount DESC
