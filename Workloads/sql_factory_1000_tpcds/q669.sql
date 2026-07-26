WITH store_return_stats AS (
    SELECT
        ss.ss_store_sk AS store_id,
        i.i_category,
        SUM(ss.ss_quantity) AS sold_qty,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS returned_qty,
        (SUM(COALESCE(sr.sr_return_quantity, 0)) / NULLIF(SUM(ss.ss_quantity), 0)) AS return_rate,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_fy_quarter_seq = (
        SELECT MAX(d_fy_quarter_seq) FROM date_dim WHERE d_fy_year = 2022
    )
      AND ss.ss_net_paid > 0
    GROUP BY ss.ss_store_sk, i.i_category
    HAVING SUM(ss.ss_quantity) >= 20
)
SELECT
    store_id,
    i_category,
    sold_qty,
    returned_qty,
    return_rate,
    total_profit,
    CASE
        WHEN total_profit < 0 THEN 'Loss'
        WHEN total_profit BETWEEN 0 AND 5000 THEN 'Low Profit'
        ELSE 'High Profit'
    END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank,
    SUM(return_rate) OVER (ORDER BY total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_rate_by_profit
FROM store_return_stats
ORDER BY profit_rank
LIMIT 8
