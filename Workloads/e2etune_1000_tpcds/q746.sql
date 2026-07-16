WITH store_sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customer_cnt
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
store_returns_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        COUNT(DISTINCT sr.sr_customer_sk) AS store_return_customer_cnt
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
catalog_sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customer_cnt
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
catalog_returns_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS catalog_return_customer_cnt
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT
    COALESCE(ssa.gender, sra.gender, csa.gender, cra.gender) AS gender,
    COALESCE(ssa.marital_status, sra.marital_status, csa.marital_status, cra.marital_status) AS marital_status,
    COALESCE(ssa.store_net_profit, 0) AS store_net_profit,
    COALESCE(csa.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(sra.store_net_loss, 0) AS store_net_loss,
    COALESCE(cra.catalog_net_loss, 0) AS catalog_net_loss,
    (COALESCE(ssa.store_net_profit, 0) - COALESCE(sra.store_net_loss, 0) +
     COALESCE(csa.catalog_net_profit, 0) - COALESCE(cra.catalog_net_loss, 0)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (COALESCE(ssa.store_net_profit, 0) - COALESCE(sra.store_net_loss, 0) +
                           COALESCE(csa.catalog_net_profit, 0) - COALESCE(cra.catalog_net_loss, 0)) DESC) AS profit_rank
FROM store_sales_agg ssa
FULL OUTER JOIN store_returns_agg sra
    ON ssa.gender = sra.gender
   AND ssa.marital_status = sra.marital_status
FULL OUTER JOIN catalog_sales_agg csa
    ON COALESCE(ssa.gender, sra.gender) = csa.gender
   AND COALESCE(ssa.marital_status, sra.marital_status) = csa.marital_status
FULL OUTER JOIN catalog_returns_agg cra
    ON COALESCE(ssa.gender, sra.gender, csa.gender) = cra.gender
   AND COALESCE(ssa.marital_status, sra.marital_status, csa.marital_status) = cra.marital_status
ORDER BY profit_rank
LIMIT 20
