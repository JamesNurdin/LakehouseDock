WITH daily_customer_sales AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        d.d_date AS sale_date,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_bill_customer_sk, d.d_date
),
eligible_customers AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(sm.sm_code, '(AIR|SEA)')
      AND sm.sm_contract LIKE 'A%'
    INTERSECT
    SELECT ss.ss_customer_sk
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_name LIKE '%Discount%'
),
returning_customers AS (
    SELECT sr.sr_customer_sk AS customer_sk
    FROM store_returns sr
    WHERE sr.sr_return_amt > 0
),
final_customers AS (
    SELECT customer_sk FROM eligible_customers
    EXCEPT
    SELECT customer_sk FROM returning_customers
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    d.d_year,
    SUM(dcs.total_sales) AS sum_sales,
    COUNT(dcs.order_cnt) AS total_orders,
    GROUPING(d.d_year) AS g_year,
    GROUPING(c.c_customer_id) AS g_cust
FROM final_customers fc
JOIN daily_customer_sales dcs ON fc.customer_sk = dcs.customer_sk
JOIN customer c ON fc.customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d ON dcs.sale_date = d.d_date
WHERE ca.ca_street_name LIKE '%Green%'
  AND regexp_extract(ca.ca_street_type, '(Lane|Court|Blvd)', 1) IS NOT NULL
  AND dcs.total_sales > (
        SELECT MAX(dcs2.total_sales)
        FROM daily_customer_sales dcs2
        JOIN date_dim d2 ON dcs2.sale_date = d2.d_date
        WHERE d2.d_year = 2020
    )
GROUP BY GROUPING SETS (
    (c.c_customer_id, ca.ca_city, d.d_year),
    (c.c_customer_id, ca.ca_city),
    (d.d_year)
)
ORDER BY sum_sales DESC
LIMIT 100
