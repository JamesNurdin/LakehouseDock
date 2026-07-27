/*
Goal: Compute total sales, profit and order counts per warehouse, call center and promotion for afternoon sales, categorize sales level, and keep only those warehouse groups that have at least one qualifying order from female customers with good credit rating and a medium‑income household. The query aggregates in a CTE, applies a CASE expression, uses DISTINCT, filters with six predicates, and employs an EXISTS semi‑join to bring in the customer_demographics and household_demographics tables.
*/
WITH sales_summary AS (
    SELECT
        c.cs_warehouse_sk,
        w.w_warehouse_name,
        w.w_county,
        cc.cc_name,
        p.p_promo_name,
        t.t_hour,
        t.t_am_pm,
        SUM(c.cs_ext_sales_price)           AS total_sales,
        SUM(c.cs_net_profit)                AS total_profit,
        COUNT(DISTINCT c.cs_order_number)   AS distinct_orders,
        CASE
            WHEN SUM(c.cs_ext_sales_price) > 200000 THEN 'HIGH'
            ELSE 'LOW'
        END                                 AS sales_category
    FROM catalog_sales c
    JOIN time_dim t
        ON c.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc
        ON c.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON c.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON c.cs_promo_sk = p.p_promo_sk
    WHERE
        t.t_hour >= 9
        AND t.t_hour <= 17
        AND t.t_am_pm = 'PM'
        AND w.w_gmt_offset >= -5
        AND w.w_gmt_offset <= 0
        AND cc.cc_employees > 30
        AND p.p_discount_active = 'Y'
        AND c.cs_quantity >= 1
    GROUP BY
        c.cs_warehouse_sk,
        w.w_warehouse_name,
        w.w_county,
        cc.cc_name,
        p.p_promo_name,
        t.t_hour,
        t.t_am_pm
)
SELECT
    ss.w_warehouse_name,
    ss.w_county,
    ss.cc_name,
    ss.p_promo_name,
    ss.t_hour,
    ss.t_am_pm,
    ss.sales_category,
    ss.total_sales,
    ss.total_profit,
    ss.distinct_orders,
    ROUND(ss.total_profit / NULLIF(ss.total_sales, 0), 4) AS profit_margin
FROM sales_summary ss
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales c2
    JOIN customer_demographics cd
        ON c2.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c2.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
        c2.cs_warehouse_sk = ss.cs_warehouse_sk
        AND cd.cd_gender = 'F'
        AND cd.cd_credit_rating = 'Good'
        AND hd.hd_income_band_sk = 5
        AND hd.hd_vehicle_count > 1
        AND c2.cs_quantity > 2
)
ORDER BY ss.total_sales DESC
LIMIT 100
