WITH combined_sales AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        ss.ss_net_profit AS net_profit,
        CAST(0 AS DECIMAL(7,2)) AS net_loss,
        ss.ss_net_paid AS net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.cs_net_profit,
        CAST(0 AS DECIMAL(7,2)),
        cs.cs_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        ws.ws_net_profit,
        CAST(0 AS DECIMAL(7,2)),
        ws.ws_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        CAST(0 AS DECIMAL(7,2)),
        wr.wr_net_loss,
        CAST(0 AS DECIMAL(7,2))
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
)
SELECT
    d_year,
    d_month_seq,
    gender,
    marital_status,
    SUM(net_profit) AS total_net_profit,
    SUM(net_loss) AS total_net_loss,
    SUM(net_paid) AS total_net_paid
FROM combined_sales
GROUP BY d_year, d_month_seq, gender, marital_status
ORDER BY d_year, d_month_seq, gender, marital_status
