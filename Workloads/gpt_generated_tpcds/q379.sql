/*
  Analytical query: total and average profit per customer demographic (gender + marital status)
  combining store and web sales.  The query uses only the three selected tables and
  follows the allowed join rules.
*/
WITH combined AS (
    -- Store sales joined to customer demographics
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ss.ss_ext_sales_price   AS sales_price,
        ss.ss_ext_discount_amt  AS discount_amt,
        ss.ss_net_profit        AS profit
    FROM store_sales ss
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    UNION ALL
    -- Web sales (bill‑to demographic) joined to customer demographics
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ws.ws_ext_sales_price   AS sales_price,
        ws.ws_ext_discount_amt  AS discount_amt,
        ws.ws_net_profit        AS profit
    FROM web_sales ws
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
),
agg AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        SUM(sales_price)   AS total_sales,
        SUM(discount_amt)  AS total_discount,
        SUM(profit)        AS total_profit,
        COUNT(*)           AS transaction_count,
        AVG(profit)        AS avg_profit_per_tx
    FROM combined
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
)
SELECT
    cd_demo_sk,
    cd_gender,
    cd_marital_status,
    total_sales,
    total_discount,
    total_profit,
    transaction_count,
    avg_profit_per_tx,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 50
