WITH sales_enriched AS (
    SELECT
        ws.ws_item_id,
        ws.ws_quantity,
        ws.ws_customer_id,
        ws.ws_ts,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_class_id
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    WHERE ws.ws_quantity > 0
)
SELECT
    se.i_category_name,
    format_datetime(cast(se.ws_ts AS timestamp), '%Y-%m') AS year_month,
    sum(se.ws_quantity) AS total_quantity,
    sum(se.ws_quantity * se.i_price) AS total_sales,
    avg(se.i_price) AS avg_price,
    count(DISTINCT se.ws_customer_id) AS unique_customers,
    count(*) AS transaction_count
FROM sales_enriched se
GROUP BY
    se.i_category_name,
    format_datetime(cast(se.ws_ts AS timestamp), '%Y-%m')
ORDER BY total_sales DESC
LIMIT 100
