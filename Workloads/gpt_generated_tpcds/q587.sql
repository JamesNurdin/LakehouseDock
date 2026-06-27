WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'store' AS channel,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers_return
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        'web' AS channel,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT wr.wr_refunded_customer_sk) AS distinct_customers_return
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        'catalog' AS channel,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_customers_return
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.channel,
    s.total_net_paid,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    s.total_net_paid - COALESCE(r.total_net_loss, 0) AS net_balance,
    s.total_net_profit,
    s.distinct_customers AS sales_customers,
    COALESCE(r.distinct_customers_return, 0) AS return_customers
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
 AND s.d_month_seq = r.d_month_seq
 AND s.channel = r.channel
ORDER BY s.d_year, s.d_month_seq, s.channel
