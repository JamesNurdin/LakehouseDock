WITH
    catalog_sales_2020 AS (
        SELECT 
            c.c_customer_sk,
            cd.cd_gender,
            cd.cd_marital_status,
            cs.cs_net_profit AS net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
    ),
    store_sales_2020 AS (
        SELECT 
            c.c_customer_sk,
            cd.cd_gender,
            cd.cd_marital_status,
            ss.ss_net_profit AS net_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
    ),
    web_sales_2020 AS (
        SELECT 
            c.c_customer_sk,
            cd.cd_gender,
            cd.cd_marital_status,
            ws.ws_net_profit AS net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
    ),
    store_returns_2020 AS (
        SELECT 
            c.c_customer_sk,
            cd.cd_gender,
            cd.cd_marital_status,
            sr.sr_net_loss AS net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
    ),
    web_returns_2020 AS (
        SELECT 
            c.c_customer_sk,
            cd.cd_gender,
            cd.cd_marital_status,
            wr.wr_net_loss AS net_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
    ),
    sales_agg AS (
        SELECT 
            cd_gender,
            cd_marital_status,
            SUM(net_profit) AS total_profit,
            COUNT(DISTINCT c_customer_sk) AS distinct_customers
        FROM (
            SELECT c_customer_sk, cd_gender, cd_marital_status, net_profit FROM catalog_sales_2020
            UNION ALL
            SELECT c_customer_sk, cd_gender, cd_marital_status, net_profit FROM store_sales_2020
            UNION ALL
            SELECT c_customer_sk, cd_gender, cd_marital_status, net_profit FROM web_sales_2020
        ) s
        GROUP BY cd_gender, cd_marital_status
    ),
    returns_agg AS (
        SELECT 
            cd_gender,
            cd_marital_status,
            SUM(net_loss) AS total_loss
        FROM (
            SELECT c_customer_sk, cd_gender, cd_marital_status, net_loss FROM store_returns_2020
            UNION ALL
            SELECT c_customer_sk, cd_gender, cd_marital_status, net_loss FROM web_returns_2020
        ) r
        GROUP BY cd_gender, cd_marital_status
    )
SELECT 
    s.cd_gender,
    s.cd_marital_status,
    s.total_profit,
    COALESCE(r.total_loss, 0) AS total_loss,
    s.total_profit - COALESCE(r.total_loss, 0) AS net_contribution,
    s.distinct_customers
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.cd_gender = r.cd_gender
 AND s.cd_marital_status = r.cd_marital_status
ORDER BY net_contribution DESC
LIMIT 10
