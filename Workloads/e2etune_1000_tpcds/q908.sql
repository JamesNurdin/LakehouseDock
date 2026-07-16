WITH sales_agg AS (
    SELECT
        ss.ss_ticket_number AS ticket_number,
        ss.ss_customer_sk AS customer_sk,
        td.t_shift AS shift,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'IRELAND'
      AND c.c_last_review_date >= 2452393
    GROUP BY ss.ss_ticket_number, ss.ss_customer_sk, td.t_shift
),
returns_agg AS (
    SELECT
        sr.sr_ticket_number AS ticket_number,
        sr.sr_customer_sk AS customer_sk,
        td.t_shift AS shift,
        SUM(sr.sr_return_amt) AS return_amount,
        SUM(sr.sr_refunded_cash) AS refunded_amount
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'IRELAND'
      AND c.c_last_review_date >= 2452393
    GROUP BY sr.sr_ticket_number, sr.sr_customer_sk, td.t_shift
)
SELECT
    c.c_birth_country,
    s.shift,
    c.c_last_name,
    c.c_email_address,
    SUM(s.sales_amount) AS total_sales,
    COALESCE(SUM(r.return_amount), 0) AS total_returns,
    SUM(s.sales_amount) - COALESCE(SUM(r.return_amount), 0) AS net_sales,
    SUM(s.profit_amount) - COALESCE(SUM(r.refunded_amount), 0) AS net_profit,
    ROW_NUMBER() OVER (PARTITION BY c.c_birth_country ORDER BY SUM(s.sales_amount) DESC) AS sales_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ticket_number = r.ticket_number
   AND s.customer_sk = r.customer_sk
   AND s.shift = r.shift
JOIN customer c ON s.customer_sk = c.c_customer_sk
GROUP BY c.c_birth_country, s.shift, c.c_last_name, c.c_email_address
ORDER BY net_sales DESC
LIMIT 100
