/* goal: Compare total web sales by warehouse state for two different customer education groups and tax thresholds, while showing the overall average discount across all sales */
WITH avg_discount AS (
    SELECT avg(ws2.ws_ext_discount_amt) AS avg_discount_all
    FROM tpcds.web_sales ws2
)
SELECT state,
       total_sales,
       avg_discount_all
FROM (
    SELECT w.w_state AS state,
           sum(ws.ws_ext_sales_price) AS total_sales,
           (SELECT avg_discount_all FROM avg_discount) AS avg_discount_all
    FROM tpcds.web_sales ws
    JOIN tpcds.warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE w.w_state IN ('MO', 'IN')
      AND cd.cd_education_status = '4 yr Degree'
    GROUP BY w.w_state

    UNION ALL

    SELECT w.w_state AS state,
           sum(ws.ws_ext_sales_price) AS total_sales,
           (SELECT avg_discount_all FROM avg_discount) AS avg_discount_all
    FROM tpcds.web_sales ws
    JOIN tpcds.warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE w.w_state IN ('TN', 'AL')
      AND cd.cd_education_status = 'College'
      AND ws.ws_ext_tax > 30
    GROUP BY w.w_state
) AS combined
ORDER BY state ASC,
         total_sales DESC
LIMIT 100
