WITH store_return_stats AS (
    SELECT
        ss.ss_store_sk AS store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS sold_qty,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS returned_qty,
        (SUM(COALESCE(sr.sr_return_quantity, 0)) / NULLIF(SUM(ss.ss_quantity), 0)) AS return_rate,
        MIN(d.d_date) AS first_sale_date,
        MAX(d.d_date) AS last_sale_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_fy_quarter_seq = (
        SELECT MAX(d_fy_quarter_seq) FROM date_dim WHERE d_fy_year = 2022
    )
      AND i.i_category IN ('Sports', 'Electronics')
    GROUP BY ss.ss_store_sk, i.i_category
    HAVING SUM(ss.ss_quantity) > 0
)
SELECT
    store_id,
    i_category,
    sold_qty,
    returned_qty,
    return_rate,
    DATE_DIFF('day', first_sale_date, last_sale_date) AS sales_span_days,
    CASE
        WHEN return_rate > 0.3 THEN 'High Return'
        WHEN return_rate BETWEEN 0.15 AND 0.3 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_level,
    DENSE_RANK() OVER (PARTITION BY i_category ORDER BY return_rate DESC) AS category_return_rank,
    SUM(return_rate) OVER (PARTITION BY i_category ORDER BY return_rate DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_rate_by_category
FROM store_return_stats
ORDER BY i_category, category_return_rank
LIMIT 15
