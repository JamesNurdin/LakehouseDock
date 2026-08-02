WITH cs_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS date_sk,
        i.i_category AS category,
        i.i_product_name AS product_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        MAX(cs.cs_ext_discount_amt) AS max_discount,
        MIN(cs.cs_ext_discount_amt) AS min_discount,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CONCAT(i.i_category, '-', substr(i.i_product_name, 1, 3)) AS cat_prod_prefix
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)summer')
      AND i.i_product_name LIKE '%RED%'
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk, i.i_category, i.i_product_name
    HAVING SUM(cs.cs_net_paid) > 1000
),
ws_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.ws_sold_date_sk AS date_sk,
        i.i_category AS category,
        i.i_product_name AS product_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        MAX(ws.ws_ext_discount_amt) AS max_discount,
        MIN(ws.ws_ext_discount_amt) AS min_discount,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CONCAT(i.i_category, '-', substr(i.i_product_name, 1, 3)) AS cat_prod_prefix
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)summer')
      AND i.i_product_name LIKE '%RED%'
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk, i.i_category, i.i_product_name
    HAVING SUM(ws.ws_net_paid) > 1500
),
combined_agg AS (
    SELECT * FROM cs_agg
    UNION ALL
    SELECT * FROM ws_agg
)
SELECT
    agg.item_sk,
    agg.date_sk,
    agg.category,
    agg.product_name,
    agg.total_net_paid,
    agg.sales_cnt,
    agg.max_discount,
    agg.min_discount,
    agg.total_sales,
    agg.cat_prod_prefix,
    REGEXP_EXTRACT(agg.product_name, '(RED|BLUE|GREEN)') AS color_extracted,
    (
        SELECT COUNT(*)
        FROM store_returns sr
        WHERE sr.sr_item_sk = agg.item_sk
          AND sr.sr_returned_date_sk = agg.date_sk
    ) AS return_cnt
FROM combined_agg agg
WHERE agg.item_sk NOT IN (SELECT sr_item_sk FROM store_returns)
ORDER BY agg.total_net_paid DESC
LIMIT 100
