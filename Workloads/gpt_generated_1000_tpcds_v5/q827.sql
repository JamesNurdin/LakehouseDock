WITH sales_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wp.wp_type,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_quantity) AS avg_qty,
        MAX(ws.ws_ext_discount_amt) AS max_discount,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'Big' ELSE 'Small' END AS sales_size
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND ws.ws_ship_date_sk BETWEEN 2451800 AND 2452000
      AND wp.wp_link_count >= 10
      AND ib.ib_lower_bound >= 50000
      AND wp.wp_rec_start_date >= DATE '2000-01-01'
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wp.wp_type
)
SELECT
    sa.*, 
    SUM(sa.total_sales) OVER (
        PARTITION BY sa.ib_income_band_sk
        ORDER BY sa.total_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales_by_income
FROM sales_agg sa
ORDER BY sa.total_sales DESC
LIMIT 100
