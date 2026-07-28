WITH catalog_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_product_name, '[A-Z]{2}[0-9]{3}')
      AND i.i_product_name LIKE '%PLUS%'
      AND regexp_like(c.c_email_address, '\\.com$')
    GROUP BY cs.cs_item_sk
),
web_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_product_name, '[A-Z]{2}[0-9]{3}')
      AND i.i_product_name LIKE '%PLUS%'
      AND regexp_like(c.c_email_address, '\\.com$')
    GROUP BY ws.ws_item_sk
),
combined AS (
    SELECT
        COALESCE(c.item_sk, w.item_sk) AS item_sk,
        SUM(COALESCE(c.net_profit, 0) + COALESCE(w.net_profit, 0)) AS total_net_profit,
        SUM(COALESCE(c.distinct_customers, 0) + COALESCE(w.distinct_customers, 0)) AS total_distinct_customers
    FROM catalog_agg c
    FULL OUTER JOIN web_agg w ON c.item_sk = w.item_sk
    GROUP BY COALESCE(c.item_sk, w.item_sk)
)
SELECT
    i.i_brand,
    i.i_category,
    i.i_product_name,
    combined.total_net_profit,
    combined.total_distinct_customers,
    substring(i.i_product_name, 1, 10) AS product_name_prefix,
    regexp_extract(i.i_product_name, '([A-Z]{2}[0-9]{3})', 1) AS extracted_code,
    concat(i.i_brand, ' - ', i.i_category) AS brand_category_concat
FROM combined
JOIN item i ON i.i_item_sk = combined.item_sk
WHERE i.i_product_name LIKE '%COOL%'
ORDER BY combined.total_net_profit DESC
LIMIT 100
