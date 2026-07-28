WITH
    ss_dim AS (
        SELECT
            ss.ss_sold_date_sk AS ss_sold_date_sk,
            ss.ss_item_sk AS ss_item_sk,
            d.d_year AS ss_year,
            i.i_brand AS ss_brand,
            i.i_category AS ss_category,
            c.c_first_name AS ss_first_name,
            c.c_last_name AS ss_last_name,
            hd.hd_income_band_sk AS ss_income_band,
            ca.ca_state AS ss_state,
            p.p_promo_name AS ss_promo_name,
            ss.ss_quantity AS ss_quantity,
            ss.ss_ext_sales_price AS ss_ext_sales_price
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    ),
    cs_dim AS (
        SELECT
            cs.cs_sold_date_sk AS cs_sold_date_sk,
            cs.cs_item_sk AS cs_item_sk,
            d.d_year AS cs_year,
            i.i_brand AS cs_brand,
            i.i_category AS cs_category,
            p.p_promo_name AS cs_promo_name,
            hd.hd_income_band_sk AS cs_income_band,
            ca.ca_state AS cs_state,
            cs.cs_quantity AS cs_quantity,
            cs.cs_ext_sales_price AS cs_ext_sales_price
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    ),
    agg AS (
        SELECT
            ss_dim.ss_year,
            ss_dim.ss_brand,
            ss_dim.ss_category,
            ss_dim.ss_first_name,
            ss_dim.ss_last_name,
            ss_dim.ss_income_band,
            ss_dim.ss_state,
            ss_dim.ss_promo_name,
            SUM(ss_dim.ss_quantity) AS total_quantity,
            SUM(ss_dim.ss_ext_sales_price) AS total_sales,
            COUNT(*) AS transaction_count,
            cs_dim.cs_year,
            cs_dim.cs_brand,
            cs_dim.cs_category,
            cs_dim.cs_income_band,
            cs_dim.cs_state,
            cs_dim.cs_promo_name,
            SUM(cs_dim.cs_quantity) AS cs_total_quantity,
            SUM(cs_dim.cs_ext_sales_price) AS cs_total_ext_sales
        FROM ss_dim
        LEFT JOIN cs_dim
            ON ss_dim.ss_sold_date_sk = cs_dim.cs_sold_date_sk
            AND ss_dim.ss_item_sk = cs_dim.cs_item_sk
        WHERE ss_dim.ss_year BETWEEN 1998 AND 2000
          AND ss_dim.ss_income_band IN (4, 11, 15)
          AND ss_dim.ss_state IN ('CA', 'TX', 'NY')
        GROUP BY
            ss_dim.ss_year,
            ss_dim.ss_brand,
            ss_dim.ss_category,
            ss_dim.ss_first_name,
            ss_dim.ss_last_name,
            ss_dim.ss_income_band,
            ss_dim.ss_state,
            ss_dim.ss_promo_name,
            cs_dim.cs_year,
            cs_dim.cs_brand,
            cs_dim.cs_category,
            cs_dim.cs_income_band,
            cs_dim.cs_state,
            cs_dim.cs_promo_name
        HAVING SUM(ss_dim.ss_ext_sales_price) > 1000
    )
SELECT
    ss_year,
    ss_brand,
    ss_category,
    ss_first_name,
    ss_last_name,
    ss_income_band,
    ss_state,
    ss_promo_name,
    total_quantity,
    total_sales,
    transaction_count,
    DENSE_RANK() OVER (PARTITION BY ss_year ORDER BY total_sales DESC) AS sales_rank,
    CASE
        WHEN total_sales > 100000 THEN 'High'
        WHEN total_sales > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    cs_year,
    cs_brand,
    cs_category,
    cs_income_band,
    cs_state,
    cs_promo_name,
    cs_total_quantity,
    cs_total_ext_sales
FROM agg
ORDER BY total_sales DESC
LIMIT 100
