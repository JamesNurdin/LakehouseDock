WITH sales_by_store_month AS (
    SELECT
        s.s_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
        AVG(ib.ib_lower_bound) AS avg_income_lower,
        AVG(ib.ib_upper_bound) AS avg_income_upper
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY s.s_store_sk, d.d_year, d.d_month_seq
),
returns_by_store_month AS (
    SELECT
        s.s_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, d.d_year, d.d_month_seq
)
SELECT
    s.s_store_name,
    sales.d_year,
    sales.d_month_seq,
    sales.total_net_paid,
    COALESCE(returns.total_return_loss, 0) AS total_return_loss,
    sales.total_net_paid - COALESCE(returns.total_return_loss, 0) AS net_after_returns,
    sales.total_net_profit,
    sales.distinct_customers,
    sales.avg_discount_amt,
    sales.avg_income_lower,
    sales.avg_income_upper,
    COALESCE(returns.total_return_qty, 0) AS total_return_qty
FROM sales_by_store_month sales
LEFT JOIN returns_by_store_month returns
    ON sales.s_store_sk = returns.s_store_sk
   AND sales.d_year = returns.d_year
   AND sales.d_month_seq = returns.d_month_seq
JOIN store s
    ON sales.s_store_sk = s.s_store_sk
ORDER BY s.s_store_name, sales.d_year, sales.d_month_seq
