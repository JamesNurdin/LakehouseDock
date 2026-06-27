WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        date_trunc('month', d_sales.d_date) AS month_start,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        date_trunc('month', d_sales.d_date)
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        date_trunc('month', d_return.d_date) AS month_start,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
    GROUP BY
        s.s_store_sk,
        date_trunc('month', d_return.d_date)
)
SELECT
    s.s_store_name,
    format_datetime(s.month_start, 'yyyy-MM') AS month,
    s.total_net_profit,
    s.total_discount,
    r.total_net_loss,
    s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_profit_after_returns,
    s.distinct_customers,
    s.total_quantity,
    r.return_count
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.s_store_sk = r.s_store_sk
    AND s.month_start = r.month_start
WHERE s.month_start >= DATE '2001-01-01'
  AND s.month_start < DATE '2002-01-01'
ORDER BY s.s_store_name, s.month_start
