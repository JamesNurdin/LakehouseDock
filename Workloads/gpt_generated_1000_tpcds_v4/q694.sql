WITH sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d_sold.d_year,
        ws.ws_net_paid_inc_ship_tax,
        hd.hd_income_band_sk,
        wp.wp_url,
        i.inv_quantity_on_hand
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN inventory i
        ON i.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 1910
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND ws.ws_net_paid_inc_ship_tax > 3000
),
agg_sales AS (
    SELECT
        c_first_name,
        c_last_name,
        d_year,
        SUM(ws_net_paid_inc_ship_tax) AS total_paid,
        COUNT(DISTINCT wp_url) AS distinct_pages,
        AVG(inv_quantity_on_hand) AS avg_inventory
    FROM sales_data
    GROUP BY c_first_name, c_last_name, d_year
)
SELECT
    c_first_name,
    c_last_name,
    d_year,
    total_paid,
    distinct_pages,
    avg_inventory,
    RANK() OVER (PARTITION BY d_year ORDER BY total_paid DESC) AS revenue_rank
FROM agg_sales
ORDER BY d_year, revenue_rank
LIMIT 100
