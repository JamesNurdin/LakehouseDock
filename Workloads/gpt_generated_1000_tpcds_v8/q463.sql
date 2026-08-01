/* goal: Identify the top‑performing California stores in 2001 by total catalog return amount, while also showing related metrics such as average web‑sales profit, distinct orders, and store‑return activity. The query demonstrates complex analytics: joins across all five TPC‑DS tables, selective filters, a sampled date dimension, array expansion with UNNEST, a correlated scalar subquery, window functions, and pagination. */
WITH date_filtered AS (
    SELECT *
    FROM date_dim
    TABLESAMPLE BERNOULLI (10)
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1200 AND 1210
      AND d_current_day = 'N'
),
store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_store_sk,
        SUM(cr.cr_return_amount)                                            AS total_return_amount,
        SUM(u.return_component)                                            AS sum_return_components,
        AVG(ws.ws_net_profit)                                               AS avg_net_profit,
        COUNT(DISTINCT cr.cr_order_number)                                  AS distinct_orders,
        MIN(cr.cr_return_quantity)                                          AS min_return_qty,
        MAX(sr.sr_return_quantity)                                          AS max_store_return_qty,
        (SELECT COUNT(*)
         FROM store_returns sr2
         WHERE sr2.sr_store_sk = s.s_store_sk)                            AS total_store_returns
    FROM catalog_returns cr
    JOIN date_filtered d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_cr.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_cr.d_date_sk
    CROSS JOIN UNNEST(array[cr.cr_return_amount, cr.cr_fee]) AS u(return_component)
    WHERE cr.cr_return_amount > 20
      AND ws.ws_coupon_amt   > 50
      AND s.s_state           = 'CA'
      AND sr.sr_return_quantity > 0
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_store_sk
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    total_return_amount,
    sum_return_components,
    avg_net_profit,
    distinct_orders,
    min_return_qty,
    max_store_return_qty,
    total_store_returns,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_return_amount DESC) AS state_return_rank,
    SUM(total_return_amount) OVER (PARTITION BY s_state ORDER BY total_return_amount
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)                     AS cum_return_amount_state
FROM store_agg
ORDER BY cum_return_amount_state DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
