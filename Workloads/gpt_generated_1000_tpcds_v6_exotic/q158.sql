WITH returns_agg AS (
    SELECT
        td.t_sub_shift AS shift,
        'return' AS transaction_type,
        SUM(r.sr_refunded_cash + r.sr_return_ship_cost) AS total_amount
    FROM store_returns r
    JOIN time_dim td ON r.sr_return_time_sk = td.t_time_sk
    WHERE td.t_sub_shift = 'morning'
      AND r.sr_refunded_cash > 100
    GROUP BY td.t_sub_shift
    HAVING SUM(r.sr_refunded_cash + r.sr_return_ship_cost) > 1000
),
sales_agg AS (
    SELECT
        td.t_sub_shift AS shift,
        'sale' AS transaction_type,
        SUM(s.ss_ext_sales_price) AS total_amount
    FROM store_sales s
    JOIN time_dim td ON s.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_sub_shift = 'evening'
      AND s.ss_ext_sales_price > 500
    GROUP BY td.t_sub_shift
    HAVING SUM(s.ss_ext_sales_price) > 2000
)
SELECT shift, transaction_type, total_amount
FROM returns_agg
UNION ALL
SELECT shift, transaction_type, total_amount
FROM sales_agg
ORDER BY total_amount DESC
