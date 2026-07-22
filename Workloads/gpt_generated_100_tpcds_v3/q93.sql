WITH agg_catalog AS (
    SELECT
        cs_ship_mode_sk,
        cs_sold_date_sk,
        cs_bill_cdemo_sk,
        SUM(cs_ext_sales_price) AS cat_sales_ext_sales,
        SUM(cs_net_profit) AS cat_sales_net_profit,
        COUNT(*) AS cat_sales_cnt
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship > 500
    GROUP BY cs_ship_mode_sk, cs_sold_date_sk, cs_bill_cdemo_sk
),
agg_web AS (
    SELECT
        ws_ship_mode_sk,
        ws_sold_date_sk,
        ws_bill_cdemo_sk,
        ws_web_site_sk,
        SUM(ws_ext_sales_price) AS web_sales_ext_sales,
        SUM(ws_net_profit) AS web_sales_net_profit,
        COUNT(*) AS web_sales_cnt
    FROM web_sales
    WHERE ws_net_paid_inc_ship > 500
    GROUP BY ws_ship_mode_sk, ws_sold_date_sk, ws_bill_cdemo_sk, ws_web_site_sk
),
agg_store_ret AS (
    SELECT
        sr_returned_date_sk,
        sr_cdemo_sk,
        SUM(sr_return_amt) AS store_ret_amt,
        SUM(sr_net_loss) AS store_ret_net_loss,
        COUNT(*) AS store_ret_cnt
    FROM store_returns
    WHERE sr_return_amt > 0
    GROUP BY sr_returned_date_sk, sr_cdemo_sk
)
SELECT
    d.d_year AS sale_year,
    d_open.d_year AS site_open_year,
    sm.sm_type AS ship_type,
    cd.cd_gender,
    cd.cd_education_status,
    ws.web_country,
    ws.web_suite_number,
    SUM(ac.cat_sales_ext_sales) AS total_catalog_sales,
    SUM(aw.web_sales_ext_sales) AS total_web_sales,
    SUM(ar.store_ret_amt) AS total_store_returns,
    SUM(ac.cat_sales_net_profit) + SUM(aw.web_sales_net_profit) - SUM(ar.store_ret_net_loss) AS total_net_profit
FROM agg_catalog ac
JOIN ship_mode sm
    ON ac.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d
    ON ac.cs_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd
    ON ac.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN agg_web aw
    ON aw.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND aw.ws_sold_date_sk = d.d_date_sk
   AND aw.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN agg_store_ret ar
    ON ar.sr_returned_date_sk = d.d_date_sk
   AND ar.sr_cdemo_sk = cd.cd_demo_sk
JOIN web_site ws
    ON aw.ws_web_site_sk = ws.web_site_sk
JOIN date_dim d_open
    ON ws.web_open_date_sk = d_open.d_date_sk
WHERE d.d_year IN (2001, 2002)
  AND sm.sm_type = 'AIR'
  AND cd.cd_gender = 'M'
  AND cd.cd_education_status = 'College'
  AND ws.web_country = 'United States'
  AND ws.web_suite_number = 'Suite 470'
  AND d_open.d_year = 2001
GROUP BY d.d_year, d_open.d_year, sm.sm_type, cd.cd_gender, cd.cd_education_status, ws.web_country, ws.web_suite_number
HAVING SUM(ac.cat_sales_ext_sales) > 20000
ORDER BY d.d_year, total_net_profit DESC
LIMIT 100
