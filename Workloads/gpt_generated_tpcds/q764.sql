WITH catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_paid_inc_tax) AS catalog_sales,
        SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender
),
catalog_returns_agg AS (
    SELECT
        d.d_year AS year,
        cd.cd_gender AS gender,
        SUM(cr.cr_return_amt_inc_tax) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        cd.cd_gender AS gender,
        SUM(ws.ws_net_paid_inc_tax) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender
),
web_returns_agg AS (
    SELECT
        d.d_year AS year,
        cd.cd_gender AS gender,
        SUM(wr.wr_return_amt_inc_tax) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_return_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender
),
store_sales_agg AS (
    SELECT
        d.d_year AS year,
        cd.cd_gender AS gender,
        SUM(ss.ss_net_paid_inc_tax) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender
)
SELECT
    COALESCE(cs.year, cr.year, ws.year, wr.year, ss.year) AS year,
    COALESCE(cs.gender, cr.gender, ws.gender, wr.gender, ss.gender) AS gender,
    COALESCE(cs.catalog_sales, 0) AS catalog_sales,
    COALESCE(cs.catalog_profit, 0) AS catalog_profit,
    COALESCE(cr.catalog_return_amount, 0) AS catalog_return_amount,
    COALESCE(cr.catalog_return_loss, 0) AS catalog_return_loss,
    COALESCE(ws.web_sales, 0) AS web_sales,
    COALESCE(ws.web_profit, 0) AS web_profit,
    COALESCE(wr.web_return_amount, 0) AS web_return_amount,
    COALESCE(wr.web_return_loss, 0) AS web_return_loss,
    COALESCE(ss.store_sales, 0) AS store_sales,
    COALESCE(ss.store_profit, 0) AS store_profit
FROM catalog_sales_agg cs
FULL OUTER JOIN catalog_returns_agg cr
    ON cs.year = cr.year AND cs.gender = cr.gender
FULL OUTER JOIN web_sales_agg ws
    ON COALESCE(cs.year, cr.year) = ws.year
    AND COALESCE(cs.gender, cr.gender) = ws.gender
FULL OUTER JOIN web_returns_agg wr
    ON COALESCE(cs.year, cr.year, ws.year) = wr.year
    AND COALESCE(cs.gender, cr.gender, ws.gender) = wr.gender
FULL OUTER JOIN store_sales_agg ss
    ON COALESCE(cs.year, cr.year, ws.year, wr.year) = ss.year
    AND COALESCE(cs.gender, cr.gender, ws.gender, wr.gender) = ss.gender
ORDER BY year, gender
