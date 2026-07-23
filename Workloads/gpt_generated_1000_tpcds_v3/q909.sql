WITH agg_returns AS (
    SELECT
        sr_cdemo_sk,
        COUNT(*) AS return_cnt,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        AVG(sr_return_ship_cost) AS avg_return_ship_cost,
        MIN(sr_return_amt_inc_tax) AS min_return_amt_inc_tax,
        MAX(sr_return_amt_inc_tax) AS max_return_amt_inc_tax
    FROM store_returns
    WHERE sr_return_ship_cost > 1000
      AND sr_return_amt_inc_tax BETWEEN 500 AND 1500
    GROUP BY sr_cdemo_sk
),
agg_sales AS (
    SELECT
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_list_price) AS avg_list_price,
        AVG(ws_net_paid_inc_ship) AS avg_net_paid_inc_ship
    FROM web_sales
    WHERE ws_net_paid_inc_ship > 1000
      AND ws_list_price > 50
    GROUP BY ws_bill_cdemo_sk
),
 demog_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_education_status,
        cd.cd_gender,
        cd.cd_marital_status,
        ar.return_cnt,
        ar.total_return_amt_inc_tax,
        asales.total_sales,
        asales.total_quantity
    FROM agg_returns ar
    JOIN customer_demographics cd
        ON ar.sr_cdemo_sk = cd.cd_demo_sk
    JOIN agg_sales asales
        ON asales.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = '4 yr Degree'
      AND cd.cd_dep_college_count >= 2
)
SELECT
    demog_agg.cd_demo_sk,
    demog_agg.cd_education_status,
    demog_agg.cd_gender,
    demog_agg.cd_marital_status,
    demog_agg.return_cnt AS total_return_count,
    demog_agg.total_return_amt_inc_tax AS total_return_amount,
    demog_agg.total_sales AS total_sales_amount,
    demog_agg.total_quantity AS total_quantity_sold,
    (SELECT AVG(sr_return_amt_inc_tax) FROM store_returns) AS overall_avg_return_amount,
    RANK() OVER (ORDER BY demog_agg.total_sales DESC) AS sales_rank
FROM demog_agg
WHERE EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_cdemo_sk = demog_agg.cd_demo_sk
      AND sr2.sr_return_amt_inc_tax > 800
)
ORDER BY sales_rank
LIMIT 100
