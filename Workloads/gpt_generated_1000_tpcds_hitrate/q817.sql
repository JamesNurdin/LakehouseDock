WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cr.cr_return_amount,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        c.c_customer_id,
        cp.cp_department,
        t.t_shift,
        p.p_response_target,
        ib.ib_upper_bound,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
        AND ss.ss_promo_sk = p.p_promo_sk
        AND ss.ss_addr_sk = ca.ca_address_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_shift = 'first'
      AND p.p_response_target = 1
      AND cp.cp_department = 'DEPARTMENT'
)
SELECT
    c_customer_id,
    cp_department,
    dg.grp,
    COUNT(DISTINCT cs_order_number) AS orders,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(COALESCE(cr_return_amount, 0)) AS total_returns,
    SUM(ss_ext_sales_price) AS total_store_sales,
    AVG(ib_upper_bound) AS avg_income_upper,
    MAX(ib_upper_bound) AS max_income_upper
FROM base
CROSS JOIN (
    SELECT 'A' AS grp UNION ALL SELECT 'B' AS grp
) AS dg
WHERE EXISTS (
    SELECT 1 FROM reason r2 WHERE r2.r_reason_desc LIKE '%defect%'
)
GROUP BY CUBE (c_customer_id, cp_department, dg.grp)
ORDER BY total_catalog_sales DESC
LIMIT 100
