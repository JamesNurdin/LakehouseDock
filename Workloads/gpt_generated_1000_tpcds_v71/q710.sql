WITH demo_agg AS (
    SELECT
        cd.cd_demo_sk,
        AVG(cs.cs_ext_discount_amt) AS avg_cs_discount,
        AVG(ss.ss_ext_discount_amt) AS avg_ss_discount
    FROM customer_demographics cd
    LEFT JOIN catalog_sales cs ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk
)
SELECT
    'catalog' AS source,
    cs.cs_sold_date_sk AS sold_date_sk,
    cd.cd_gender AS gender,
    cs.cs_ext_sales_price AS ext_sales_price,
    cs.cs_ext_discount_amt AS ext_discount_amt,
    (cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_sales_price, 0)) AS discount_rate
FROM catalog_sales cs
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE cs.cs_list_price > 50
  AND cd.cd_marital_status = 'M'
  AND cs.cs_ext_discount_amt > (
        SELECT da.avg_cs_discount
        FROM demo_agg da
        WHERE da.cd_demo_sk = cd.cd_demo_sk
      )
UNION ALL
SELECT
    'store' AS source,
    ss.ss_sold_date_sk AS sold_date_sk,
    cd.cd_gender AS gender,
    ss.ss_ext_sales_price AS ext_sales_price,
    ss.ss_ext_discount_amt AS ext_discount_amt,
    (ss.ss_ext_discount_amt / NULLIF(ss.ss_ext_sales_price, 0)) AS discount_rate
FROM store_sales ss
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE ss.ss_list_price BETWEEN 20 AND 150
  AND cd.cd_marital_status IN ('M', 'S')
  AND EXISTS (
        SELECT 1
        FROM demo_agg da
        WHERE da.cd_demo_sk = cd.cd_demo_sk
          AND ss.ss_ext_discount_amt > da.avg_ss_discount
      )
ORDER BY source, discount_rate DESC
LIMIT 100
