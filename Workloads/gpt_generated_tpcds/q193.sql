/*
  Analytical query: Net contribution (profit – loss) by calendar year, gender and marital status.
  The query aggregates sales from the three channels (store, catalog, web) and their corresponding returns.
  It uses the allowed join relationships, filters to the year 2020 via the date_dim table, and reports
  the number of distinct customers, total profit, total loss and net amount for each demographic slice.
*/
WITH all_transactions AS (
    -- Store sales (profit)
    SELECT
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_net_profit AS amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'

    UNION ALL
    -- Catalog sales (profit)
    SELECT
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_net_profit AS amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'

    UNION ALL
    -- Web sales (profit)
    SELECT
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_net_profit AS amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'

    UNION ALL
    -- Store returns (loss – represented as a negative amount)
    SELECT
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        sr.sr_customer_sk AS customer_sk,
        -sr.sr_net_loss AS amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'

    UNION ALL
    -- Catalog returns (loss)
    SELECT
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.cr_refunded_customer_sk AS customer_sk,
        -cr.cr_net_loss AS amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'

    UNION ALL
    -- Web returns (loss)
    SELECT
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        wr.wr_refunded_customer_sk AS customer_sk,
        -wr.wr_net_loss AS amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
)
SELECT
    d_year,
    cd_gender,
    cd_marital_status,
    COUNT(DISTINCT customer_sk)                               AS unique_customers,
    SUM(amount)                                               AS net_amount,
    SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END)         AS total_profit,
    SUM(CASE WHEN amount < 0 THEN -amount ELSE 0 END)        AS total_loss
FROM all_transactions
GROUP BY d_year, cd_gender, cd_marital_status
ORDER BY d_year, cd_gender, cd_marital_status
