WITH sales_agg AS (
    SELECT
        item_sk,
        SUM(ext_sales_price) AS total_sales_amount,
        COUNT(*) AS total_sales_transactions
    FROM (
        SELECT cs_item_sk AS item_sk, cs_ext_sales_price AS ext_sales_price FROM catalog_sales
        UNION ALL
        SELECT ss_item_sk AS item_sk, ss_ext_sales_price FROM store_sales
        UNION ALL
        SELECT ws_item_sk AS item_sk, ws_ext_sales_price FROM web_sales
    ) s
    GROUP BY item_sk
), page_descs AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        array_join(array_agg(DISTINCT cp.cp_description), ', ') AS descriptions
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cs.cs_item_sk
), final_result AS (
    SELECT
        s.item_sk,
        s.total_sales_amount,
        s.total_sales_transactions,
        pd.descriptions
    FROM sales_agg s
    LEFT JOIN page_descs pd ON s.item_sk = pd.item_sk
)
SELECT *
FROM final_result
ORDER BY total_sales_amount DESC
LIMIT 100
