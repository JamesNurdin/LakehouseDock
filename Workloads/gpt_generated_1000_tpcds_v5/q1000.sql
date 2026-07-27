WITH store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_time_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_quantity) AS store_qty,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS store_sales_rank
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND cd.cd_marital_status = 'M'
      AND s.s_state = 'CA'
      AND s.s_gmt_offset >= -8
    GROUP BY ss.ss_store_sk, ss.ss_sold_time_sk
)
SELECT
    s.s_store_name,
    td.t_hour,
    ca.store_sales_amount,
    ca.store_qty,
    ca.store_sales_rank,
    cs_total.cs_total_sales,
    cs_total.cs_total_qty,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY ca.store_sales_amount DESC) AS store_hour_rank,
    CASE WHEN cs_total.cs_total_sales > ca.store_sales_amount THEN 'CatalogHigher' ELSE 'StoreHigher' END AS higher_source
FROM store_sales_agg ca
JOIN store s ON ca.ss_store_sk = s.s_store_sk
JOIN time_dim td ON ca.ss_sold_time_sk = td.t_time_sk
JOIN (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_sold_time_sk,
        SUM(cs.cs_ext_sales_price) AS cs_total_sales,
        SUM(cs.cs_quantity) AS cs_total_qty
    FROM catalog_sales cs
    JOIN time_dim td2 ON cs.cs_sold_time_sk = td2.t_time_sk
    JOIN customer_demographics cd2 ON cs.cs_bill_cdemo_sk = cd2.cd_demo_sk
    WHERE td2.t_hour BETWEEN 9 AND 17
      AND cd2.cd_education_status = 'College'
    GROUP BY cs.cs_call_center_sk, cs.cs_sold_time_sk
) cs_total ON cs_total.cs_sold_time_sk = ca.ss_sold_time_sk
WHERE EXISTS (
    SELECT 1
    FROM call_center cc
    WHERE cc.cc_call_center_sk = cs_total.cs_call_center_sk
      AND cc.cc_market_manager = 'John Doe'
      AND cc.cc_gmt_offset BETWEEN -8 AND -5
)
ORDER BY ca.store_sales_amount DESC
LIMIT 100
