WITH store_sales_agg AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk, ss.ss_cdemo_sk, ss.ss_store_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS wr_customer_sk,
        wr.wr_refunded_cdemo_sk AS wr_cdemo_sk,
        SUM(wr.wr_net_loss) AS total_web_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS web_returns_cnt
    FROM web_returns wr
    GROUP BY wr.wr_refunded_customer_sk, wr.wr_refunded_cdemo_sk
)
SELECT
    c.c_birth_country,
    cd.cd_gender,
    s.s_state,
    SUM(COALESCE(ssa.total_store_profit, 0)) AS total_store_profit,
    SUM(COALESCE(wra.total_web_loss, 0)) AS total_web_loss,
    (SUM(COALESCE(ssa.total_store_profit, 0)) - SUM(COALESCE(wra.total_web_loss, 0))) AS net_contribution,
    SUM(COALESCE(ssa.total_store_quantity, 0)) AS total_store_quantity,
    SUM(COALESCE(wra.total_return_qty, 0)) AS total_return_qty,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY (SUM(COALESCE(ssa.total_store_profit, 0)) - SUM(COALESCE(wra.total_web_loss, 0))) DESC) AS gender_rank
FROM store_sales_agg ssa
LEFT JOIN web_returns_agg wra
    ON ssa.ss_customer_sk = wra.wr_customer_sk
   AND ssa.ss_cdemo_sk = wra.wr_cdemo_sk
JOIN customer c
    ON ssa.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ssa.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON ssa.ss_store_sk = s.s_store_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_country IN ('IRELAND', 'CYPRUS')
GROUP BY
    c.c_birth_country,
    cd.cd_gender,
    s.s_state
HAVING (SUM(COALESCE(ssa.total_store_profit, 0)) - SUM(COALESCE(wra.total_web_loss, 0))) > 1000
ORDER BY net_contribution DESC
LIMIT 100
