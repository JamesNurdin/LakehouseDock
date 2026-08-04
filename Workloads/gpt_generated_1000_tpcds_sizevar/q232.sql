WITH
catalog_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sales_price > 20
      AND cs.cs_quantity >= 2
      AND cs.cs_call_center_sk IN (10, 22, 28)
      AND cs.cs_ext_discount_amt < 5
      AND cs.cs_ext_tax > 0
    GROUP BY cs.cs_call_center_sk, cs.cs_item_sk
),
call_center_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        ca.cs_item_sk,
        ca.catalog_sales_total,
        ca.catalog_sales_cnt
    FROM call_center cc
    JOIN catalog_agg ca
        ON cc.cc_call_center_sk = ca.cs_call_center_sk
),
promo_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_item_sk,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        COUNT(*) AS web_sales_cnt
    FROM promotion p
    JOIN web_sales ws
        ON p.p_promo_sk = ws.ws_promo_sk
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
        AND ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sales_price BETWEEN 30 AND 200
      AND ws.ws_quantity <= 5
      AND p.p_channel_email = 'N'
      AND p.p_discount_active = 'Y'
      AND i.i_class_id = 4
    GROUP BY p.p_promo_sk, p.p_item_sk
),
items_in_both AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    INTERSECT
    SELECT DISTINCT ws.ws_item_sk
    FROM web_sales ws
),
items_only_catalog AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    EXCEPT
    SELECT DISTINCT ws.ws_item_sk
    FROM web_sales ws
)
SELECT
    i.i_item_sk AS item_sk,
    i.i_product_name,
    COALESCE(cca.cc_name, 'Unassigned') AS call_center_name,
    SUM(cca.catalog_sales_total) AS total_catalog_sales,
    SUM(pa.web_sales_total) AS total_web_sales,
    COUNT(*) AS source_rows,
    MIN(cca.catalog_sales_total) AS min_catalog_sales,
    MAX(pa.web_sales_total) AS max_web_sales
FROM item i
FULL OUTER JOIN call_center_agg cca
    ON i.i_item_sk = cca.cs_item_sk
FULL OUTER JOIN promo_agg pa
    ON i.i_item_sk = pa.p_item_sk
WHERE i.i_wholesale_cost BETWEEN 0.5 AND 5
  AND i.i_color = 'Red'
  AND i.i_item_sk IN (SELECT item_sk FROM items_in_both)
  AND i.i_item_sk NOT IN (SELECT item_sk FROM items_only_catalog)
GROUP BY
    i.i_item_sk,
    i.i_product_name,
    COALESCE(cca.cc_name, 'Unassigned')
LIMIT 100
