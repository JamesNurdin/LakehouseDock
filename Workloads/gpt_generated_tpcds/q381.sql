WITH base_demog AS (
    SELECT cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status
    FROM customer_demographics cd
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
store_sales_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS store_sales_cnt,
        SUM(ss.ss_net_profit) AS store_sales_net_profit,
        AVG(ss.ss_net_profit) AS store_sales_avg_net_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
store_returns_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS store_return_cnt,
        SUM(sr.sr_net_loss) AS store_return_net_loss,
        AVG(sr.sr_net_loss) AS store_return_avg_net_loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
catalog_returns_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS catalog_return_cnt,
        SUM(cr.cr_net_loss) AS catalog_return_net_loss,
        AVG(cr.cr_net_loss) AS catalog_return_avg_net_loss
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
web_returns_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS web_return_cnt,
        SUM(wr.wr_net_loss) AS web_return_net_loss,
        AVG(wr.wr_net_loss) AS web_return_avg_net_loss
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT
    bd.cd_gender,
    bd.cd_marital_status,
    bd.cd_education_status,
    COALESCE(ssa.store_sales_cnt, 0)               AS store_sales_cnt,
    COALESCE(ssa.store_sales_net_profit, 0)        AS store_sales_net_profit,
    COALESCE(ssa.store_sales_avg_net_profit, 0)    AS store_sales_avg_net_profit,
    COALESCE(sra.store_return_cnt, 0)              AS store_return_cnt,
    COALESCE(sra.store_return_net_loss, 0)         AS store_return_net_loss,
    COALESCE(sra.store_return_avg_net_loss, 0)     AS store_return_avg_net_loss,
    COALESCE(cra.catalog_return_cnt, 0)            AS catalog_return_cnt,
    COALESCE(cra.catalog_return_net_loss, 0)       AS catalog_return_net_loss,
    COALESCE(cra.catalog_return_avg_net_loss, 0)   AS catalog_return_avg_net_loss,
    COALESCE(wra.web_return_cnt, 0)                AS web_return_cnt,
    COALESCE(wra.web_return_net_loss, 0)           AS web_return_net_loss,
    COALESCE(wra.web_return_avg_net_loss, 0)       AS web_return_avg_net_loss,
    (COALESCE(sra.store_return_net_loss, 0) + COALESCE(cra.catalog_return_net_loss, 0) + COALESCE(wra.web_return_net_loss, 0)) AS total_return_net_loss,
    (COALESCE(sra.store_return_cnt, 0) + COALESCE(cra.catalog_return_cnt, 0) + COALESCE(wra.web_return_cnt, 0))               AS total_return_cnt
FROM base_demog bd
LEFT JOIN store_sales_agg ssa
    ON bd.cd_gender = ssa.cd_gender
   AND bd.cd_marital_status = ssa.cd_marital_status
   AND bd.cd_education_status = ssa.cd_education_status
LEFT JOIN store_returns_agg sra
    ON bd.cd_gender = sra.cd_gender
   AND bd.cd_marital_status = sra.cd_marital_status
   AND bd.cd_education_status = sra.cd_education_status
LEFT JOIN catalog_returns_agg cra
    ON bd.cd_gender = cra.cd_gender
   AND bd.cd_marital_status = cra.cd_marital_status
   AND bd.cd_education_status = cra.cd_education_status
LEFT JOIN web_returns_agg wra
    ON bd.cd_gender = wra.cd_gender
   AND bd.cd_marital_status = wra.cd_marital_status
   AND bd.cd_education_status = wra.cd_education_status
ORDER BY total_return_net_loss DESC
