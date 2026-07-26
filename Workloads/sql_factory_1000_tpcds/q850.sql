WITH store_return_stats AS (
    SELECT
        ss.ss_store_sk AS store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS sold_qty,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS returned_qty,
        (SUM(COALESCE(sr.sr_return_quantity, 0)) / NULLIF(SUM(ss.ss_quantity), 0)) AS return_rate,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_fy_quarter_seq = (
        SELECT MAX(d_fy_quarter_seq) FROM date_dim WHERE d_fy_year = 2022
    )
      AND ss.ss_sales_price > 0
    GROUP BY ss.ss_store_sk, i.i_category
    HAVING SUM(ss.ss_quantity) > 0
)
SELECT
    store_id,
    i_category,
    sold_qty,
    returned_qty,
    return_rate,
    distinct_tickets,
    CASE
        WHEN distinct_tickets > 500 THEN 'High Volume'
        WHEN distinct_tickets BETWEEN 200 AND 500 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_level,
    ROW_NUMBER() OVER (ORDER BY distinct_tickets DESC) AS volume_rank,
    SUM(return_rate) OVER (PARTITION BY i_category ORDER BY return_rate DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS future_cumulative_return
FROM store_return_stats
ORDER BY volume_rank
LIMIT 10
