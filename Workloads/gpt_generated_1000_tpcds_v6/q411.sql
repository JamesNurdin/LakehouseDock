WITH sales_data AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_profit
    FROM tpcds.item i
    LEFT JOIN tpcds.catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_formulation LIKE '%papaya%'
    GROUP BY i.i_item_sk, i.i_product_name
)
SELECT
    s.i_item_sk,
    s.i_product_name,
    (s.catalog_sales + s.web_sales) AS total_sales,
    CASE WHEN (s.catalog_sales + s.web_sales) > 5000 THEN 'High' ELSE 'Low' END AS sales_category,
    s.total_profit
FROM sales_data s
WHERE (s.catalog_sales + s.web_sales) IS NOT NULL

UNION ALL

SELECT
    r.wr_item_sk AS i_item_sk,
    i.i_product_name,
    -SUM(r.wr_return_amt) AS total_sales,
    CASE WHEN -SUM(r.wr_return_amt) > 5000 THEN 'High' ELSE 'Low' END AS sales_category,
    -SUM(r.wr_net_loss) AS total_profit
FROM tpcds.web_returns r
JOIN tpcds.web_sales ws
    ON r.wr_item_sk = ws.ws_item_sk
   AND r.wr_order_number = ws.ws_order_number
JOIN tpcds.item i
    ON i.i_item_sk = r.wr_item_sk
WHERE i.i_formulation LIKE '%papaya%'
GROUP BY r.wr_item_sk, i.i_product_name

LIMIT 100
