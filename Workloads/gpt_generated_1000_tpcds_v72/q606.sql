WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        i.i_color,
        i.i_size,
        d.d_year,
        s.s_store_name,
        concat(i.i_color, '-', i.i_size) AS color_size
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_id, '^AAAA')
      AND i.i_product_name LIKE '%Special%'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = ss.ss_customer_sk
      )
)
SELECT
    d_year,
    s_store_name,
    color_size,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers
FROM filtered_sales
GROUP BY ROLLUP (d_year, s_store_name, color_size)
ORDER BY d_year ASC, s_store_name ASC, total_net_profit DESC
LIMIT 100
