WITH store_return_stats AS (
    SELECT
        ss.ss_store_sk AS store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS sold_qty,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS returned_qty,
        (SUM(COALESCE(sr.sr_return_quantity, 0)) / NULLIF(SUM(ss.ss_quantity), 0)) AS return_rate,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        MAX(ss.ss_sales_price) AS max_sales_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_fy_quarter_seq = (
        SELECT MAX(d_fy_quarter_seq) FROM date_dim WHERE d_fy_year = 2022
    )
      AND d.d_month_seq BETWEEN 202201 AND 202212
      AND i.i_category IN ('Electronics', 'Furniture')
    GROUP BY ss.ss_store_sk, i.i_category
    HAVING SUM(ss.ss_quantity) >= 5
)
SELECT
    store_id,
    i_category,
    sold_qty,
    returned_qty,
    return_rate,
    avg_sales_price,
    max_sales_price,
    CASE WHEN max_sales_price > 500 THEN 'High Ticket' ELSE 'Regular Ticket' END AS ticket_type,
    DENSE_RANK() OVER (ORDER BY return_rate DESC) AS return_rate_rank,
    SUM(return_rate) OVER (PARTITION BY i_category ORDER BY avg_sales_price ASC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS reverse_cum_return_by_category
FROM store_return_stats
ORDER BY return_rate_rank
LIMIT 12
