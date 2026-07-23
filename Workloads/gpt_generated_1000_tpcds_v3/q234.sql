WITH joined_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_fy_quarter_seq,
        d.d_last_dom,
        cr.cr_return_amount,
        cr.cr_store_credit,
        cr.cr_return_quantity,
        ss.ss_net_paid_inc_tax,
        ss.ss_quantity,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_fy_quarter_seq = 12
      AND d.d_last_dom = 2415385
      AND cr.cr_return_amount > 1000.00
      AND cr.cr_store_credit < 500.00
      AND ss.ss_net_paid_inc_tax BETWEEN 100 AND 3000
      AND ss.ss_ticket_number IN (5, 9, 12)
),
agg_returns AS (
    SELECT
        d_year,
        d_month_seq,
        'return' AS metric,
        SUM(cr_return_amount) AS metric_value,
        COUNT(*) AS transaction_cnt
    FROM joined_data
    GROUP BY d_year, d_month_seq
    HAVING SUM(cr_return_amount) > 2000
       AND COUNT(*) >= 5
),
agg_sales AS (
    SELECT
        d_year,
        d_month_seq,
        'sales' AS metric,
        SUM(ss_net_paid_inc_tax) AS metric_value,
        COUNT(*) AS transaction_cnt
    FROM joined_data
    GROUP BY d_year, d_month_seq
    HAVING SUM(ss_net_paid_inc_tax) > 5000
)
SELECT
    d_year,
    d_month_seq,
    metric,
    metric_value,
    transaction_cnt,
    ROW_NUMBER() OVER (PARTITION BY metric ORDER BY metric_value DESC) AS metric_rank
FROM (
    SELECT d_year, d_month_seq, metric, metric_value, transaction_cnt FROM agg_returns
    UNION ALL
    SELECT d_year, d_month_seq, metric, metric_value, transaction_cnt FROM agg_sales
) combined
ORDER BY metric, metric_rank
LIMIT 100
