WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
    GROUP BY s.s_store_sk, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_return_transactions
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
    GROUP BY s.s_store_sk, d.d_year, d.d_month_seq
)
SELECT
    s.s_store_name,
    sa.d_year,
    sa.d_month_seq,
    sa.total_net_paid,
    ra.total_net_loss,
    (sa.total_net_paid - COALESCE(ra.total_net_loss, 0)) AS net_sales_after_returns,
    sa.total_net_profit,
    (sa.total_quantity - COALESCE(ra.total_return_quantity, 0)) AS net_quantity_sold,
    (ra.total_net_loss / NULLIF(sa.total_net_paid, 0)) * 100 AS return_loss_percent
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
   AND sa.d_year = ra.d_year
   AND sa.d_month_seq = ra.d_month_seq
JOIN store s
    ON sa.s_store_sk = s.s_store_sk
ORDER BY s.s_store_name, sa.d_year, sa.d_month_seq
