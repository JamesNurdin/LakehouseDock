WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        d.d_year,
        d.d_date,
        wp.wp_type,
        wp.wp_url,
        c.c_customer_id,
        hd.hd_buy_potential,
        regexp_extract(wp.wp_url, '^/product/([^/]+)\\.html$', 1) AS product_id
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(wp.wp_url, '^/product/.+\\.html$')
      AND wp.wp_type LIKE '%promo%'
      AND d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
aggregated AS (
    SELECT
        wp_type,
        d_year,
        sum(ws_net_profit) AS total_net_profit,
        count(DISTINCT c_customer_id) AS distinct_customers
    FROM filtered_sales
    GROUP BY wp_type, d_year
)
SELECT
    wp_type,
    d_year,
    total_net_profit,
    distinct_customers,
    sum(total_net_profit) OVER (PARTITION BY wp_type ORDER BY d_year
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
