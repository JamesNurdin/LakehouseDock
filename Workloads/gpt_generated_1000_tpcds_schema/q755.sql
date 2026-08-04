WITH catalog_part AS (
    SELECT
        d.d_date AS sale_date,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(DISTINCT cs.cs_ext_sales_price) AS distinct_sales,
        'catalog' AS source,
        (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper
    FROM catalog_sales cs
    RIGHT JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_call_center_sk NOT IN (
        SELECT cc.cc_call_center_sk
        FROM call_center cc
        WHERE cc.cc_gmt_offset = -5.00
    )
    AND EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_address_sk = cs.cs_bill_addr_sk
          AND ca.ca_state = 'CA'
    )
    GROUP BY d.d_date
),
promo_part AS (
    SELECT
        d.d_date AS sale_date,
        COUNT(DISTINCT p.p_promo_sk) AS distinct_orders,
        SUM(DISTINCT p.p_cost) AS distinct_sales,
        'promo' AS source,
        (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper
    FROM promotion p
    FULL OUTER JOIN date_dim d
        ON p.p_start_date_sk = d.d_date_sk
    WHERE p.p_promo_sk NOT IN (
        SELECT cs2.cs_promo_sk
        FROM catalog_sales cs2
        WHERE cs2.cs_ext_discount_amt > 5000
    )
    AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    GROUP BY d.d_date
)
SELECT *
FROM catalog_part
UNION ALL
SELECT *
FROM promo_part
ORDER BY sale_date DESC NULLS LAST, source
LIMIT 100
