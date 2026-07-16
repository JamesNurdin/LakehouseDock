WITH sales_by_shift AS (
    SELECT
        i.i_class,
        t.t_shift,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_quantity) AS total_sales_qty,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 20
    GROUP BY i.i_class, t.t_shift
),
returns_by_shift AS (
    SELECT
        i.i_class,
        t.t_shift,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_tax) AS avg_return_tax
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 20
    GROUP BY i.i_class, t.t_shift
)
SELECT
    s.i_class,
    s.t_shift,
    s.total_sales_profit,
    r.total_return_amount,
    s.total_sales_qty,
    r.total_return_qty,
    CASE WHEN s.total_sales_profit = 0 THEN NULL
         ELSE r.total_return_amount / s.total_sales_profit END AS return_to_profit_ratio,
    RANK() OVER (PARTITION BY s.i_class ORDER BY s.total_sales_profit DESC) AS profit_rank
FROM sales_by_shift s
JOIN returns_by_shift r
    ON s.i_class = r.i_class AND s.t_shift = r.t_shift
WHERE s.total_sales_qty > 100
  AND r.total_return_qty > 0
ORDER BY s.i_class, profit_rank
