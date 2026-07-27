WITH distinct_bill AS (
    SELECT DISTINCT cs_bill_customer_sk, cs_bill_cdemo_sk
    FROM tpcds.catalog_sales
    WHERE cs_ext_wholesale_cost > 1500.00
      AND cs_quantity >= 2
)
SELECT
    w.w_state,
    cd.cd_credit_rating,
    cd.cd_education_status,
    COUNT(DISTINCT db.cs_bill_customer_sk) AS distinct_customers,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    AVG(cs.cs_net_profit) AS avg_catalog_profit,
    MAX(ws.ws_net_profit) AS max_web_profit,
    MIN(cs.cs_ext_wholesale_cost) AS min_catalog_wholesale_cost
FROM distinct_bill db
JOIN tpcds.catalog_sales cs
    ON cs.cs_bill_customer_sk = db.cs_bill_customer_sk
   AND cs.cs_bill_cdemo_sk = db.cs_bill_cdemo_sk
JOIN tpcds.customer_demographics cd
    ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN tpcds.warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN tpcds.web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE
    w.w_state IN ('IN', 'MO')
    AND w.w_zip BETWEEN '30000' AND '80000'
    AND cd.cd_credit_rating = 'Good'
    AND cd.cd_purchase_estimate >= 5000
    AND cd.cd_education_status = 'Advanced Degree'
GROUP BY
    w.w_state,
    cd.cd_credit_rating,
    cd.cd_education_status
ORDER BY total_catalog_sales DESC
LIMIT 100
