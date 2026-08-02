WITH base_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_ship_cost,
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_item_desc,
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        wp.wp_url,
        wp.wp_type,
        wp.wp_rec_start_date
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        REGEXP_LIKE(i.i_item_desc, '[0-9]{3}')
        AND wp.wp_url LIKE '%sale%'
        AND wp.wp_rec_start_date >= DATE '2000-01-01'
        AND wp.wp_rec_start_date <= DATE '2001-12-31'
        AND NOT EXISTS (
            SELECT 1
            FROM web_page wp2
            WHERE wp2.wp_customer_sk = c.c_customer_sk
                AND REGEXP_LIKE(wp2.wp_url, 'promo')
        )
),
item_agg AS (
    SELECT
        i_brand,
        i_category,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT c_customer_sk) AS unique_customers
    FROM base_sales
    GROUP BY ROLLUP (i_brand, i_category)
),
page_agg AS (
    SELECT
        wp_type,
        MAX(REGEXP_EXTRACT(wp_url, 'https?://([^/]+)', 1)) AS domain,
        SUM(ws_ext_sales_price) AS page_sales,
        SUM(ws_ext_ship_cost) AS total_ship_cost,
        COUNT(DISTINCT c_customer_sk) AS unique_customers_page
    FROM base_sales
    GROUP BY CUBE (wp_type)
)
SELECT
    ia.i_brand,
    ia.i_category,
    ia.total_quantity,
    ia.total_sales,
    ia.total_profit,
    ia.unique_customers,
    pa.wp_type,
    pa.domain,
    pa.page_sales,
    pa.total_ship_cost,
    pa.unique_customers_page
FROM item_agg ia
FULL OUTER JOIN page_agg pa
    ON ia.i_brand = pa.wp_type
ORDER BY COALESCE(ia.total_sales, 0) DESC
LIMIT 100
