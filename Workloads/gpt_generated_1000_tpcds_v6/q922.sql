WITH sales_by_dept_promo AS (
    SELECT
        cp.cp_department AS department,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        cp.cp_department = 'Books'
        AND cp.cp_catalog_page_number BETWEEN 10 AND 20
        AND hd_bill.hd_vehicle_count >= 2
        AND ib.ib_lower_bound >= 50000
        AND cs.cs_quantity > 1
        AND cs.cs_net_profit > 0
        AND p.p_discount_active = 'Y'
    GROUP BY cp.cp_department, p.p_promo_name
),
dept_summary AS (
    SELECT
        department,
        SUM(total_sales) AS dept_sales,
        SUM(total_profit) AS dept_profit,
        AVG(total_profit / NULLIF(total_sales, 0)) AS avg_margin
    FROM (
        SELECT
            department,
            promo_name,
            total_sales,
            total_profit
        FROM sales_by_dept_promo
    ) sub
    GROUP BY department
)
SELECT
    department,
    dept_sales,
    dept_profit,
    avg_margin
FROM dept_summary
WHERE dept_sales > 50000
ORDER BY avg_margin DESC
LIMIT 100
