/*
  Goal: Identify high‑profit sales groups by call center and warehouse, using string
  processing on product names and warehouse street names, and rank the groups per
  company.
*/
WITH sales_detail AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cc.cc_name,
        cc.cc_company,
        w.w_warehouse_name,
        w.w_city,
        w.w_street_name,
        i.i_product_name,
        regexp_extract(i.i_product_name, '(\\w+)-\\w+', 1) AS product_prefix,
        CASE
            WHEN regexp_like(w.w_street_name, '.*Elm.*') THEN 'ELM_STREET'
            ELSE 'OTHER_STREET'
        END AS street_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_name LIKE 'A%'
      AND i.i_product_name LIKE '%-%'
),
agg_sales AS (
    SELECT
        cc_name,
        cc_company,
        w_warehouse_name,
        w_city,
        street_category,
        product_prefix,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit
    FROM sales_detail
    GROUP BY
        cc_name,
        cc_company,
        w_warehouse_name,
        w_city,
        street_category,
        product_prefix
    HAVING SUM(cs_net_profit) > 10000
)
SELECT
    a.cc_name,
    a.cc_company,
    a.w_warehouse_name,
    a.w_city,
    a.street_category,
    a.product_prefix,
    a.total_sales,
    a.total_profit,
    ROW_NUMBER() OVER (PARTITION BY a.cc_company ORDER BY a.total_profit DESC) AS profit_rank
FROM agg_sales a
ORDER BY profit_rank, a.total_profit DESC
LIMIT 100
