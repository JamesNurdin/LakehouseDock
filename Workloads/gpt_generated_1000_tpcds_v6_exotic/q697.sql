WITH base AS (
    SELECT
        ws.web_state,
        d_sold.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d_sold.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.inv_quantity_on_hand > 100
      AND ws.web_tax_percentage BETWEEN 0.02 AND 0.08
      AND wp.wp_type = 'Content'
      AND ss.ss_net_profit > 0
    GROUP BY GROUPING SETS (
        (ws.web_state, d_sold.d_month_seq),
        (ws.web_state),
        (d_sold.d_month_seq),
        ()
    )
)
SELECT
    web_state,
    month_seq,
    AVG(total_sales) AS avg_sales,
    AVG(total_profit) AS avg_profit,
    SUM(total_inventory) AS sum_inventory
FROM (
    SELECT
        web_state,
        d_month_seq AS month_seq,
        total_sales,
        total_profit,
        total_inventory
    FROM base
) b
WHERE total_sales IS NOT NULL
GROUP BY
    web_state,
    month_seq
HAVING AVG(total_sales) > 10000
ORDER BY avg_sales DESC
LIMIT 100
