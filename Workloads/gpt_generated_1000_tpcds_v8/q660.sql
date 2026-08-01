WITH sampled_items AS (
        SELECT i_item_sk, i_category, i_brand
        FROM item
        TABLESAMPLE BERNOULLI (10)
        WHERE i_current_price > 50
    ),
    catalog_customers AS (
        SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk, cs.cs_item_sk
        FROM catalog_sales cs
        JOIN sampled_items si ON cs.cs_item_sk = si.i_item_sk
        WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
    ),
    web_return_customers AS (
        SELECT DISTINCT wr.wr_returning_customer_sk AS customer_sk, wr.wr_item_sk
        FROM web_returns wr
        JOIN sampled_items si ON wr.wr_item_sk = si.i_item_sk
        WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
    ),
    common_customers AS (
        SELECT customer_sk
        FROM catalog_customers
        INTERSECT
        SELECT customer_sk
        FROM web_return_customers
    ),
    promo_active AS (
        SELECT p_promo_sk, p_promo_name
        FROM promotion
        WHERE p_discount_active = 'Y'
    ),
    store_ca AS (
        SELECT s_store_sk, s_store_name
        FROM store
        WHERE s_state = 'CA'
        LIMIT 5
    ),
    cross_join_set AS (
        SELECT s.s_store_sk, p.p_promo_sk
        FROM store_ca s
        CROSS JOIN (SELECT p_promo_sk FROM promo_active) p
    )
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    pa.p_promo_name,
    cjs.p_promo_sk
FROM customer c
JOIN common_customers cc ON c.c_customer_sk = cc.customer_sk
JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promo_active pa ON ss.ss_promo_sk = pa.p_promo_sk
JOIN cross_join_set cjs
    ON s.s_store_sk = cjs.s_store_sk
    AND pa.p_promo_sk = cjs.p_promo_sk
WHERE EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = ss.ss_item_sk
          AND inv.inv_quantity_on_hand > 0
    )
ORDER BY c.c_customer_id
OFFSET 10 ROWS
LIMIT 100
