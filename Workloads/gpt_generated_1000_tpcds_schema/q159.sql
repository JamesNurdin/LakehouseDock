WITH base AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        wp.wp_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        MIN(ws.ws_ext_ship_cost) AS min_ship_cost,
        MAX(ws.ws_ext_ship_cost) AS max_ship_cost,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_pages,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ib.ib_lower_bound >= 50000
      AND hd.hd_vehicle_count >= 0
      AND wp.wp_image_count > 2
      AND ws.ws_ext_discount_amt > (
          SELECT MAX(ws2.ws_ext_discount_amt)
          FROM web_sales ws2
          WHERE ws2.ws_quantity = 1
      )
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        wp.wp_type
)
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num
FROM base
ORDER BY total_sales DESC
LIMIT 100
