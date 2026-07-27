WITH sales_filtered AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        i.i_category,
        t.t_hour
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE i.i_class = 'infants'
      AND i.i_manufact_id = 212
      AND c.c_current_cdemo_sk = 980124
      AND t.t_shift = 'second'
      AND t.t_am_pm = 'PM'
      AND t.t_minute = 5
)
SELECT
    i_category,
    t_hour,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss_customer_sk) AS unique_customers,
    MIN(ss_sold_date_sk) AS earliest_sale_sk,
    MAX(ss_sold_date_sk) AS latest_sale_sk
FROM sales_filtered
GROUP BY i_category, t_hour
ORDER BY total_sales DESC
LIMIT 50
