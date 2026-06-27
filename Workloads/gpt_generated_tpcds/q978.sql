WITH catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_discount_amt) AS catalog_total_discount,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_moy, cd.cd_gender
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_moy, cd.cd_gender
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_discount_amt) AS web_total_discount,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_moy, cd.cd_gender
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        cd.cd_gender,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_moy, cd.cd_gender
)
SELECT
    COALESCE(cs_agg.d_year, cr_agg.d_year, ws_agg.d_year, wr_agg.d_year) AS year,
    COALESCE(cs_agg.d_moy, cr_agg.d_moy, ws_agg.d_moy, wr_agg.d_moy) AS month,
    COALESCE(cs_agg.cd_gender, cr_agg.cd_gender, ws_agg.cd_gender, wr_agg.cd_gender) AS gender,
    COALESCE(cs_agg.catalog_net_paid, 0) - COALESCE(cr_agg.catalog_return_amount, 0) AS net_paid_after_catalog_returns,
    COALESCE(cs_agg.catalog_net_profit, 0) - COALESCE(cr_agg.catalog_return_amount, 0) AS net_profit_after_catalog_returns,
    COALESCE(ws_agg.web_net_paid, 0) - COALESCE(wr_agg.web_return_amount, 0) AS net_paid_after_web_returns,
    COALESCE(ws_agg.web_net_profit, 0) - COALESCE(wr_agg.web_return_amount, 0) AS net_profit_after_web_returns,
    COALESCE(cs_agg.catalog_total_discount, 0) + COALESCE(ws_agg.web_total_discount, 0) AS total_discount,
    COALESCE(cs_agg.catalog_sales_cnt, 0) + COALESCE(ws_agg.web_sales_cnt, 0) AS total_sales_transactions,
    COALESCE(cr_agg.catalog_return_cnt, 0) + COALESCE(wr_agg.web_return_cnt, 0) AS total_return_transactions
FROM catalog_sales_agg cs_agg
FULL OUTER JOIN catalog_returns_agg cr_agg
    ON cs_agg.d_year = cr_agg.d_year
   AND cs_agg.d_moy = cr_agg.d_moy
   AND cs_agg.cd_gender = cr_agg.cd_gender
FULL OUTER JOIN web_sales_agg ws_agg
    ON COALESCE(cs_agg.d_year, cr_agg.d_year) = ws_agg.d_year
   AND COALESCE(cs_agg.d_moy, cr_agg.d_moy) = ws_agg.d_moy
   AND COALESCE(cs_agg.cd_gender, cr_agg.cd_gender) = ws_agg.cd_gender
FULL OUTER JOIN web_returns_agg wr_agg
    ON COALESCE(cs_agg.d_year, cr_agg.d_year, ws_agg.d_year) = wr_agg.d_year
   AND COALESCE(cs_agg.d_moy, cr_agg.d_moy, ws_agg.d_moy) = wr_agg.d_moy
   AND COALESCE(cs_agg.cd_gender, cr_agg.cd_gender, ws_agg.cd_gender) = wr_agg.cd_gender
ORDER BY year, month, gender
