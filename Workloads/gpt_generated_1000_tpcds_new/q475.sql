WITH
    sampled_catalog AS (
        SELECT *
        FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    ),
    promo_match AS (
        SELECT p.p_promo_sk,
               regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS discount_pct
        FROM promotion p
        WHERE regexp_like(p.p_promo_name, '.*Discount.*')
    ),
    target_customers AS (
        SELECT c.c_customer_sk
        FROM sampled_catalog sc
        JOIN customer c ON sc.cs_bill_customer_sk = c.c_customer_sk
        WHERE sc.cs_promo_sk IN (SELECT p_promo_sk FROM promo_match)
        INTERSECT
        SELECT c.c_customer_sk
        FROM customer c
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ib.ib_lower_bound >= 150000
    )
SELECT
    county,
    promo_name,
    total_sales,
    orders,
    customer_display,
    extracted_discount
FROM (
    SELECT
        ca.ca_county AS county,
        p.p_promo_name AS promo_name,
        SUM(sc.cs_net_paid) AS total_sales,
        COUNT(DISTINCT sc.cs_order_number) AS orders,
        CONCAT(SUBSTRING(c.c_first_name, 1, 1), '. ', c.c_last_name) AS customer_display,
        regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS extracted_discount
    FROM sampled_catalog sc
    JOIN customer c ON sc.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sc.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON sc.cs_promo_sk = p.p_promo_sk
    WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM target_customers)
      AND c.c_email_address LIKE '%@example.com'
      AND ca.ca_city LIKE 'San%'
    GROUP BY ca.ca_county, p.p_promo_name, c.c_first_name, c.c_last_name, p.p_promo_name

    UNION DISTINCT

    SELECT
        ca.ca_county AS county,
        p.p_promo_name AS promo_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        CONCAT(SUBSTRING(c.c_first_name, 1, 1), '. ', c.c_last_name) AS customer_display,
        regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS extracted_discount
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE EXISTS (
        SELECT 1
        FROM target_customers tc
        WHERE tc.c_customer_sk = c.c_customer_sk
    )
      AND regexp_like(p.p_promo_name, '^.*% Off$')
    GROUP BY ca.ca_county, p.p_promo_name, c.c_first_name, c.c_last_name, p.p_promo_name
) AS combined
ORDER BY total_sales DESC
LIMIT 100
