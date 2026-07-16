WITH cust_demo AS (
    SELECT
        c.c_customer_id,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        c.c_salutation,
        c.c_email_address,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        hd.hd_buy_potential
    FROM customer c
    JOIN household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_year BETWEEN 1940 AND 1980
      AND c.c_salutation IN ('Mr.', 'Mrs.', 'Dr.')
      AND c.c_email_address LIKE '%@%.edu'
),

agg AS (
    SELECT
        hd_income_band_sk,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customers,
        AVG(c_birth_year) AS avg_birth_year,
        AVG(hd_vehicle_count) AS avg_vehicle_count,
        AVG(hd_dep_count) AS avg_dependency_count,
        (SELECT COUNT(DISTINCT i_category) FROM item i WHERE i.i_rec_start_date >= DATE '2020-01-01') AS recent_item_categories,
        (SELECT AVG(i_current_price) FROM item i WHERE i.i_brand = 'BrandX') AS avg_price_brandx,
        (SELECT COUNT(*) FROM reason r WHERE r.r_reason_desc LIKE '%discount%') AS discount_reason_count
    FROM cust_demo
    GROUP BY hd_income_band_sk
    HAVING COUNT(*) >= 10
)

SELECT
    hd_income_band_sk,
    total_customers,
    preferred_customers,
    avg_birth_year,
    avg_vehicle_count,
    avg_dependency_count,
    recent_item_categories,
    avg_price_brandx,
    discount_reason_count,
    RANK() OVER (ORDER BY total_customers DESC) AS income_band_rank
FROM agg
ORDER BY total_customers DESC
LIMIT 10
