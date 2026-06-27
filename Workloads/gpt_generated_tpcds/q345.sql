WITH
store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        sum(ss.ss_net_profit) AS store_sales_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_moy
),
store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        sum(sr.sr_net_loss) AS store_returns_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_moy
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        sum(cr.cr_net_loss) AS catalog_returns_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_moy
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        sum(wr.wr_net_loss) AS web_returns_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_moy
)
SELECT
    COALESCE(ssa.d_year, sra.d_year, cra.d_year, wra.d_year) AS year,
    COALESCE(ssa.d_moy, sra.d_moy, cra.d_moy, wra.d_moy) AS month,
    COALESCE(ssa.store_sales_profit, 0) AS store_sales_profit,
    COALESCE(sra.store_returns_loss, 0) AS store_returns_loss,
    COALESCE(cra.catalog_returns_loss, 0) AS catalog_returns_loss,
    COALESCE(wra.web_returns_loss, 0) AS web_returns_loss,
    COALESCE(ssa.store_sales_profit, 0)
        - COALESCE(sra.store_returns_loss, 0)
        - COALESCE(cra.catalog_returns_loss, 0)
        - COALESCE(wra.web_returns_loss, 0) AS net_profit
FROM store_sales_agg ssa
FULL OUTER JOIN store_returns_agg sra
    ON ssa.d_year = sra.d_year AND ssa.d_moy = sra.d_moy
FULL OUTER JOIN catalog_returns_agg cra
    ON COALESCE(ssa.d_year, sra.d_year) = cra.d_year
       AND COALESCE(ssa.d_moy, sra.d_moy) = cra.d_moy
FULL OUTER JOIN web_returns_agg wra
    ON COALESCE(ssa.d_year, sra.d_year, cra.d_year) = wra.d_year
       AND COALESCE(ssa.d_moy, sra.d_moy, cra.d_moy) = wra.d_moy
ORDER BY net_profit DESC
LIMIT 10
