WITH sales_dates AS (
    SELECT
        ws.*, 
        d.d_date,
        d.d_year,
        d.d_fy_year,
        d.d_qoy,
        s.s_store_id,
        s.s_market_manager
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
),
page_info AS (
    SELECT
        wp.*, 
        d_creation.d_year AS creation_year,
        d_access.d_year AS access_year
    FROM web_page wp
    LEFT JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    LEFT JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
)
SELECT
    sales_dates.s_store_id,
    sales_dates.s_market_manager,
    sales_dates.d_date,
    sales_dates.ws_order_number,
    sales_dates.ws_ext_sales_price,
    page_info.wp_url,
    page_info.wp_char_count,
    sales_dates.ws_net_profit,
    ROW_NUMBER() OVER (PARTITION BY sales_dates.s_store_id ORDER BY sales_dates.ws_ext_sales_price DESC) AS rn_profit_rank,
    RANK() OVER (PARTITION BY sales_dates.d_year ORDER BY sales_dates.ws_ext_sales_price DESC) AS yearly_sales_rank,
    CASE
        WHEN sales_dates.ws_ext_sales_price > 2000 THEN 'High'
        WHEN sales_dates.ws_ext_sales_price > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS price_category
FROM sales_dates
FULL OUTER JOIN page_info
    ON sales_dates.ws_web_page_sk = page_info.wp_web_page_sk
WHERE
    sales_dates.d_fy_year = 1915
    AND sales_dates.d_qoy = 2
    AND sales_dates.ws_ext_ship_cost > 1000
    AND page_info.wp_char_count BETWEEN 2000 AND 4000
ORDER BY sales_dates.ws_ext_sales_price DESC
LIMIT 100
