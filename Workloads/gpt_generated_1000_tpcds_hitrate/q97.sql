WITH filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        c.c_current_hdemo_sk
    FROM customer c
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(c.c_email_address, '[A-Z0-9._%+-]+@example\\.com')
      AND hd.hd_buy_potential IN ('5001-10000', '>10000')
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_code,
    SUBSTRING(sm.sm_contract, 1, 5) AS contract_prefix,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_quantity) AS avg_quantity
FROM catalog_sales cs
JOIN filtered_customers fc
    ON cs.cs_bill_customer_sk = fc.c_customer_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
    ON fc.c_current_hdemo_sk = hd.hd_demo_sk
WHERE sm.sm_contract LIKE 'A%'
  AND regexp_like(sm.sm_contract, '^A[0-9A-Za-z]{3,}$')
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = fc.c_customer_sk
          AND wp.wp_url LIKE '%promo%'
          AND regexp_extract(wp.wp_url, 'promo=([0-9]+)', 1) IS NOT NULL
      )
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_code,
    SUBSTRING(sm.sm_contract, 1, 5),
    hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
