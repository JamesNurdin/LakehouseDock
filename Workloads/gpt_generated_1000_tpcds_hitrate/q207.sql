WITH catalog_summary AS (
    SELECT
        i.i_category AS category,
        i.i_class AS class,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        (SELECT COUNT(*) FROM customer_address) AS addr_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'Advanced Degree'
      AND i.i_manufact_id = 479
    GROUP BY ROLLUP (i.i_category, i.i_class)
),
web_summary AS (
    SELECT
        i.i_category AS category,
        i.i_class AS class,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        (SELECT COUNT(*) FROM customer_address) AS addr_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'College'
      AND i.i_manufact_id = 167
    GROUP BY ROLLUP (i.i_category, i.i_class)
)
SELECT category,
       class,
       total_sales,
       addr_cnt
FROM catalog_summary
INTERSECT
SELECT category,
       class,
       total_sales,
       addr_cnt
FROM web_summary
ORDER BY category, class
LIMIT 100
