WITH sales_returns AS (
    SELECT
        cs.cs_order_number,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cp.cp_type,
        hd.hd_income_band_sk,
        p.p_discount_active,
        r.r_reason_desc,
        cr.cr_return_amount
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cp.cp_type = 'monthly'
      AND hd.hd_income_band_sk = 14
      AND p.p_discount_active = 'Y'
      AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = cs.cs_promo_sk
              AND p2.p_cost > 1000
        )
)
SELECT
    cp_type,
    hd_income_band_sk,
    p_discount_active,
    r_reason_desc,
    SUM(cr_return_amount) AS total_return_amount,
    CASE
        WHEN SUM(cr_return_amount) > 1000 THEN 'High'
        WHEN SUM(cr_return_amount) > 500 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY cp_type ORDER BY SUM(cr_return_amount) DESC) AS rn
FROM sales_returns
GROUP BY
    cp_type,
    hd_income_band_sk,
    p_discount_active,
    r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
