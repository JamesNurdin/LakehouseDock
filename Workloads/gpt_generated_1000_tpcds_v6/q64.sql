WITH returns_2022 AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS year,
        hd.hd_buy_potential AS buy_potential,
        wp.wp_type AS page_type,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_id, d.d_year, hd.hd_buy_potential, wp.wp_type
),
returns_2023 AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS year,
        hd.hd_buy_potential AS buy_potential,
        wp.wp_type AS page_type,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_id, d.d_year, hd.hd_buy_potential, wp.wp_type
)
SELECT
    customer_id,
    year,
    buy_potential,
    page_type,
    total_return_amount
FROM (
    SELECT * FROM returns_2022
    UNION ALL
    SELECT * FROM returns_2023
) AS combined
ORDER BY year DESC, total_return_amount DESC
LIMIT 100
