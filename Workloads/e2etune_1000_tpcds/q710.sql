WITH sales_agg AS (
    SELECT
        i.i_brand AS brand,
        i.i_category AS category,
        wp.wp_type AS page_type,
        date_trunc('month', date_add('day', ws.ws_sold_date_sk, date '1970-01-01')) AS sale_month,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_wholesale_cost > 5.00
      AND wp.wp_type = 'product'
      AND ws.ws_sold_date_sk BETWEEN 18500 AND 18600
    GROUP BY
        i.i_brand,
        i.i_category,
        wp.wp_type,
        date_trunc('month', date_add('day', ws.ws_sold_date_sk, date '1970-01-01'))
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
    brand,
    category,
    page_type,
    sale_month,
    total_net_profit,
    total_quantity,
    avg_discount,
    RANK() OVER (PARTITION BY sale_month ORDER BY total_net_profit DESC) AS brand_month_rank
FROM sales_agg
ORDER BY sale_month, brand_month_rank
LIMIT 20
