WITH cte_base AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_customer_sk,
        wr.wr_returning_cdemo_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_returning_addr_sk,
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax,
        wr.wr_fee,
        wr.wr_return_ship_cost,
        wr.wr_refunded_cash,
        wr.wr_reversed_charge,
        wr.wr_account_credit,
        wr.wr_net_loss,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_dow,
        d.d_current_day,
        d.d_quarter_seq,
        d.d_day_name
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND d.d_current_day = 'N'
      AND d.d_dow IN (1, 2, 3)
      AND d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
      AND wr.wr_reason_sk IN (52, 37, 20)
      AND wr.wr_return_amt > 100.00
      AND wr.wr_return_tax < 500.00
),

agg_high AS (
    SELECT
        d_year,
        d_month_seq,
        d_date,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns,
        CASE WHEN SUM(wr_return_amt) > 1000 THEN 'Large' ELSE 'Small' END AS size_category
    FROM cte_base
    WHERE wr_return_amt >= 500
    GROUP BY d_year, d_month_seq, d_date
),

ranked_high AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY size_category ORDER BY total_net_loss DESC) AS rn
    FROM agg_high
),

agg_low AS (
    SELECT
        d_year,
        d_month_seq,
        d_date,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns,
        CASE WHEN SUM(wr_return_amt) > 1000 THEN 'Large' ELSE 'Small' END AS size_category
    FROM cte_base
    WHERE wr_return_amt < 500
    GROUP BY d_year, d_month_seq, d_date
),

ranked_low AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY size_category ORDER BY total_net_loss DESC) AS rn
    FROM agg_low
)

SELECT
    d_year,
    d_month_seq,
    d_date,
    total_return_amt,
    total_net_loss,
    cnt_returns,
    size_category,
    rn AS rank,
    'HighAmt' AS amount_group
FROM ranked_high
UNION ALL
SELECT
    d_year,
    d_month_seq,
    d_date,
    total_return_amt,
    total_net_loss,
    cnt_returns,
    size_category,
    rn AS rank,
    'LowAmt' AS amount_group
FROM ranked_low
ORDER BY rank
LIMIT 100
