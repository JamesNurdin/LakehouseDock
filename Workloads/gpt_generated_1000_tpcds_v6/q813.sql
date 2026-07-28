WITH refunded AS (
    SELECT
        d.d_year AS year,
        s.s_city AS city,
        COUNT(*) AS num_returns,
        SUM(wr.wr_net_loss) AS total_net_loss,
        REGEXP_EXTRACT(c.c_email_address, '@([^.]*)\\.') AS email_domain
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@.+\\.com$')
      AND d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND s.s_gmt_offset = -5.00
    GROUP BY d.d_year, s.s_city, REGEXP_EXTRACT(c.c_email_address, '@([^.]*)\\.')
),
returning AS (
    SELECT
        d.d_year AS year,
        s.s_city AS city,
        COUNT(*) AS num_returns,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUBSTRING(c.c_first_name, 1, 1) || '.' || SUBSTRING(c.c_last_name, 1, 1) AS initials
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND s.s_street_name LIKE '%Hill%'
      AND d.d_year = 2022
    GROUP BY d.d_year, s.s_city, SUBSTRING(c.c_first_name, 1, 1) || '.' || SUBSTRING(c.c_last_name, 1, 1)
)
SELECT year,
       city,
       num_returns,
       total_net_loss
FROM refunded
WHERE email_domain LIKE 'gmail%'
UNION ALL
SELECT year,
       city,
       num_returns,
       total_net_loss
FROM returning
ORDER BY year DESC, total_net_loss DESC
