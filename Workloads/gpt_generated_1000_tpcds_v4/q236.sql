WITH base AS (
    SELECT
        cc.cc_division,
        cc.cc_zip,
        cc.cc_employees,
        cc.cc_gmt_offset,
        p.p_promo_name,
        p.p_discount_active,
        d_cc.d_year AS year_closed,
        inv.inv_quantity_on_hand,
        inv.inv_warehouse_sk
    FROM call_center cc
    JOIN date_dim d_cc
        ON cc.cc_closed_date_sk = d_cc.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_cc.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_cc.d_date_sk
    JOIN date_dim d_p_end
        ON p.p_end_date_sk = d_p_end.d_date_sk
    WHERE
        cc.cc_division IN (1, 2, 3)
        AND cc.cc_zip LIKE '7%'
        AND d_cc.d_year = 2001
        AND p.p_discount_active = 'Y'
        AND inv.inv_quantity_on_hand > 500
        AND d_p_end.d_year >= 2001
),
agg_by_center_promo AS (
    SELECT
        cc_division,
        p_promo_name,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv_warehouse_sk) AS warehouse_cnt,
        AVG(cc_employees) AS avg_employees
    FROM base
    GROUP BY cc_division, p_promo_name
)
SELECT
    cc_division,
    AVG(total_qty) AS avg_total_qty,
    SUM(warehouse_cnt) AS total_warehouses,
    AVG(avg_employees) AS avg_employees_per_center
FROM agg_by_center_promo
GROUP BY cc_division
HAVING AVG(total_qty) > 1000
ORDER BY avg_total_qty DESC
LIMIT 100
