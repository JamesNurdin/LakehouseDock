WITH customer_page_stats AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        d_first_sales.d_date AS first_sales_date,
        d_first_ship.d_date AS first_ship_date,
        d_last_review.d_date AS last_review_date,
        s.s_store_name AS store_closed_on_first_sales,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_count,
        MIN(d_page_creation.d_date) AS earliest_page_creation,
        MAX(d_page_access.d_date) AS latest_page_access
    FROM customer c
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_first_sales
        ON c.c_first_sales_date_sk = d_first_sales.d_date_sk
    JOIN date_dim d_first_ship
        ON c.c_first_shipto_date_sk = d_first_ship.d_date_sk
    JOIN date_dim d_last_review
        ON c.c_last_review_date = d_last_review.d_date_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_page_creation
        ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
    JOIN date_dim d_page_access
        ON wp.wp_access_date_sk = d_page_access.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_first_sales.d_date_sk
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        d_first_sales.d_date,
        d_first_ship.d_date,
        d_last_review.d_date,
        s.s_store_name
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_email_address,
    hd_buy_potential,
    hd_income_band_sk,
    hd_vehicle_count,
    hd_dep_count,
    first_sales_date,
    first_ship_date,
    last_review_date,
    store_closed_on_first_sales,
    web_page_count,
    earliest_page_creation,
    latest_page_access,
    DENSE_RANK() OVER (ORDER BY web_page_count DESC) AS web_page_rank
FROM customer_page_stats
ORDER BY web_page_rank, web_page_count DESC
