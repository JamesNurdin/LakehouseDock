WITH store_metrics AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        'StoreNetProfit' AS metric_name,
        SUM(ss.ss_net_profit) AS metric_value,
        DATE_FORMAT(d.d_date, '%Y') AS year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
    GROUP BY i.i_item_id, i.i_product_name, DATE_FORMAT(d.d_date, '%Y')
),
catalog_metrics AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        'CatalogSales' AS metric_name,
        SUM(cs.cs_ext_sales_price) AS metric_value,
        DATE_FORMAT(d.d_date, '%Y') AS year
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'TX'
      AND d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
    GROUP BY i.i_item_id, i.i_product_name, DATE_FORMAT(d.d_date, '%Y')
),
combined AS (
    SELECT * FROM store_metrics
    UNION ALL
    SELECT * FROM catalog_metrics
)
SELECT
    c.item_id,
    c.product_name,
    c.metric_name,
    c.metric_value,
    c.year,
    (SELECT AVG(metric_value) FROM combined WHERE year = c.year) AS avg_metric_value_year
FROM combined c
WHERE c.metric_value > (SELECT AVG(metric_value) FROM combined)
ORDER BY c.year DESC, c.metric_value DESC
LIMIT 100
