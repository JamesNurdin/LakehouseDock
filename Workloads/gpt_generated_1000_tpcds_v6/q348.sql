WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY inv_item_sk
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_item_sk,
        c.c_customer_id,
        c.c_customer_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        inv_agg.total_on_hand
    FROM item i
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_site wsit ON wsit.web_site_sk = ws.ws_web_site_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
    WHERE cs.cs_sales_price > 20
      AND ws.ws_quantity >= 2
      AND p.p_discount_active = 'Y'
      AND c.c_birth_year BETWEEN 1960 AND 1980
    GROUP BY i.i_item_id, i.i_product_name, i.i_category, i.i_item_sk, c.c_customer_id, c.c_customer_sk, inv_agg.total_on_hand
    HAVING SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) > 1000
       AND NOT EXISTS (
           SELECT 1 FROM web_returns wr2
           WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
       )
)
SELECT
    i_item_id,
    i_product_name,
    i_category,
    c_customer_id,
    catalog_sales,
    web_sales,
    (catalog_sales + web_sales) AS total_sales,
    total_on_hand,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY (catalog_sales + web_sales) DESC) AS sales_rank_in_category
FROM item_sales
ORDER BY total_sales DESC
LIMIT 100
