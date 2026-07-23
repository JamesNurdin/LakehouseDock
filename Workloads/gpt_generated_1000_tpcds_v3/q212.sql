WITH cs_agg AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_bill_cdemo_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_quantity) AS avg_quantity,
        MIN(cs.cs_ext_discount_amt) AS min_discount_amt,
        MAX(cs.cs_ext_tax) AS max_tax
    FROM catalog_sales cs
    WHERE
        cs.cs_quantity > 0
        AND cs.cs_net_paid > 100
    GROUP BY cs.cs_catalog_page_sk, cs.cs_bill_cdemo_sk
),
wr_agg AS (
    SELECT
        wr.wr_refunded_cdemo_sk,
        COUNT(*) AS returns_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_fee) AS total_fee,
        AVG(wr.wr_reversed_charge) AS avg_reversed_charge
    FROM web_returns wr
    WHERE
        wr.wr_fee > 30
        AND wr.wr_reversed_charge < 50
        AND wr.wr_refunded_cdemo_sk = 231024
    GROUP BY wr.wr_refunded_cdemo_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cd.cd_education_status,
    cd.cd_marital_status,
    cs_agg.total_net_paid,
    cs_agg.total_net_profit,
    cs_agg.avg_quantity,
    cs_agg.min_discount_amt,
    cs_agg.max_tax,
    COALESCE(wr_agg.returns_cnt, 0) AS total_returns,
    COALESCE(wr_agg.total_return_amt, 0) AS total_return_amt,
    COALESCE(wr_agg.total_fee, 0) AS total_return_fee,
    COALESCE(wr_agg.avg_reversed_charge, 0) AS avg_reversed_charge
FROM cs_agg
JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd
    ON cs_agg.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN wr_agg
    ON wr_agg.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE
    cp.cp_catalog_page_id = 'AAAAAAAAIAAAAAAA'
    AND cd.cd_education_status = 'College'
    AND cd.cd_marital_status = 'M'
ORDER BY cs_agg.total_net_paid DESC
LIMIT 100
