WITH sales_union AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        d.d_year AS year,
        'store' AS channel,
        ss.ss_net_paid AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'

    UNION ALL

    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        d.d_year AS year,
        'web' AS channel,
        ws.ws_net_paid AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND we.web_state = 'CA'
)
SELECT
    item_id,
    product_name,
    year,
    SUM(total_sales) AS total_sales
FROM sales_union
GROUP BY item_id, product_name, year
HAVING SUM(total_sales) > 10000
ORDER BY total_sales DESC
LIMIT 100
