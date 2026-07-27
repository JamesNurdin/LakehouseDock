/* goal: Identify customers with their store’s return activity, enriched with catalog return information, and flag whether the net loss from store returns is positive. */
WITH sr_agg AS (
    SELECT
        sr_customer_sk,
        sr_store_sk,
        COUNT(*) AS returns_cnt,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2451500 AND 2452000               -- filter on surrogate date key
      AND sr_return_quantity > 0                                      -- only positive quantity returns
      AND sr_return_time_sk BETWEEN 30000 AND 60000                    -- realistic time range filter
    GROUP BY sr_customer_sk, sr_store_sk
)
SELECT
    c.c_customer_id,
    s.s_store_name,
    sr_agg.returns_cnt,
    sr_agg.total_return_amt,
    CASE
        WHEN sr_agg.total_net_loss > 0 THEN 'LOSS'
        ELSE 'PROFIT_OR_BREAK_EVEN'
    END AS loss_indicator,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS catalog_return_amount_sum
FROM sr_agg
JOIN customer c ON sr_agg.sr_customer_sk = c.c_customer_sk
JOIN store s ON sr_agg.sr_store_sk = s.s_store_sk
LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE c.c_birth_year BETWEEN 1960 AND 1990                               -- age filter
  AND s.s_state = 'CA'                                                    -- geography filter
  AND s.s_rec_start_date >= DATE '2000-01-01'                             -- store start date lower bound
  AND s.s_rec_start_date <= DATE '2002-12-31'                             -- store start date upper bound
GROUP BY
    c.c_customer_id,
    s.s_store_name,
    sr_agg.returns_cnt,
    sr_agg.total_return_amt,
    CASE
        WHEN sr_agg.total_net_loss > 0 THEN 'LOSS'
        ELSE 'PROFIT_OR_BREAK_EVEN'
    END
ORDER BY sr_agg.total_return_amt DESC
LIMIT 100
