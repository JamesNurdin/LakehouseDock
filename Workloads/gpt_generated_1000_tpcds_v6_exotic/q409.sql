WITH cs_agg AS (
    SELECT
        cc.cc_mkt_desc,
        cd.cd_credit_rating,
        SUM(cs.cs_ext_sales_price) AS total_cs_sales
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_mkt_id = 3
      AND cd.cd_gender = 'F'
    GROUP BY cc.cc_mkt_desc, cd.cd_credit_rating
),
ws_agg AS (
    SELECT
        ws_site.web_name,
        cd.cd_credit_rating,
        SUM(ws.ws_ext_sales_price) AS total_ws_sales
    FROM tpcds.web_sales ws
    JOIN tpcds.web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws_site.web_mkt_desc LIKE '%market%'
      AND cd.cd_gender = 'F'
    GROUP BY ws_site.web_name, cd.cd_credit_rating
)
SELECT
    src.source,
    src.marketing_desc,
    src.credit_rating,
    src.total_sales,
    (
        SELECT AVG(t.total)
        FROM (
            SELECT total_cs_sales AS total FROM cs_agg
            UNION ALL
            SELECT total_ws_sales FROM ws_agg
        ) t
    ) AS avg_total_sales_across_sources
FROM (
    SELECT
        'Catalog' AS source,
        cc_mkt_desc AS marketing_desc,
        cd_credit_rating AS credit_rating,
        total_cs_sales AS total_sales
    FROM cs_agg
    WHERE total_cs_sales > 10000
    UNION ALL
    SELECT
        'Web' AS source,
        web_name AS marketing_desc,
        cd_credit_rating AS credit_rating,
        total_ws_sales AS total_sales
    FROM ws_agg
    WHERE total_ws_sales > 10000
) src
WHERE EXISTS (
    SELECT 1
    FROM tpcds.call_center cc2
    WHERE cc2.cc_mkt_desc = src.marketing_desc
      AND cc2.cc_tax_percentage > 5.0
)
ORDER BY src.total_sales DESC
LIMIT 100
