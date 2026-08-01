WITH base_sales AS (
    SELECT
        d.d_date AS sales_date,
        i.i_brand AS brand,
        wp.wp_type AS page_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(CASE WHEN i.i_size = 'medium' THEN ws.ws_quantity ELSE 0 END) AS medium_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_container = 'Unknown'
      AND ws.ws_ext_sales_price > 0
    GROUP BY d.d_date, i.i_brand, wp.wp_type
)
SELECT
    profit_category,
    AVG(total_sales) AS avg_sales,
    SUM(total_quantity) AS sum_quantity,
    SUM(medium_quantity) AS sum_medium_quantity
FROM (
    SELECT
        sales_date,
        brand,
        page_type,
        total_sales,
        total_profit,
        total_quantity,
        medium_quantity,
        CASE WHEN total_profit > 5000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM base_sales
) AS t
GROUP BY profit_category
HAVING AVG(total_sales) > 1000
ORDER BY avg_sales DESC
LIMIT 100
