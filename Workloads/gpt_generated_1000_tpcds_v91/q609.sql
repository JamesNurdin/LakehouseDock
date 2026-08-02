WITH catalog_sales_agg AS (
    SELECT
        'Catalog' AS sales_source,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_market_manager = 'Julius Durham'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
    GROUP BY i.i_item_id, i.i_product_name
),
web_sales_agg AS (
    SELECT
        'Web' AS sales_source,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_manager = 'Evan Saldana'
      AND wsite.web_rec_start_date >= DATE '2000-01-01'
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT
    sales_source,
    item_id,
    product_name,
    total_sales,
    sales_category,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num
FROM (
    SELECT sales_source, item_id, product_name, total_sales, sales_category
    FROM catalog_sales_agg
    UNION ALL
    SELECT sales_source, item_id, product_name, total_sales, sales_category
    FROM web_sales_agg
) combined
ORDER BY total_sales DESC
LIMIT 100
