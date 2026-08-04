WITH sales_summary AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        i.i_brand,
        i.i_category
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_wholesale_cost > 20
)
SELECT
    COALESCE(s.cs_item_sk, sr.sr_item_sk) AS item_sk,
    COUNT(DISTINCT s.cs_bill_customer_sk) AS uniq_customers,
    SUM(DISTINCT s.cs_quantity) AS sum_unique_qty,
    (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_brand = 'BrandX') AS max_price_brandx
FROM sales_summary s
FULL OUTER JOIN store_returns sr
    ON s.cs_item_sk = sr.sr_item_sk
WHERE COALESCE(s.cs_item_sk, sr.sr_item_sk) NOT IN (
    SELECT i3.i_item_sk FROM item i3 WHERE i3.i_category = 'Electronics'
)
GROUP BY COALESCE(s.cs_item_sk, sr.sr_item_sk)
UNION
SELECT
    ws.ws_item_sk AS item_sk,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS uniq_customers,
    SUM(DISTINCT ws.ws_quantity) AS sum_unique_qty,
    (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_brand = 'BrandX') AS max_price_brandx
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE ws.ws_list_price BETWEEN 50 AND 200
GROUP BY ws.ws_item_sk
LIMIT 100
