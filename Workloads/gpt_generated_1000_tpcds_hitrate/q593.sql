WITH item_inventory AS (
   SELECT i.i_item_sk,
          i.i_item_id,
          i.i_category,
          inv.inv_quantity_on_hand,
          (SELECT MAX(p.p_cost) FROM promotion p WHERE p.p_item_sk = i.i_item_sk) AS max_promo_cost
   FROM item i
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
   WHERE inv.inv_quantity_on_hand > 500
),

catalog_ret AS (
   SELECT
       ii.i_item_id AS item_id,
       c.c_customer_id AS customer_id,
       cr.cr_return_amount AS return_amount,
       CASE WHEN cr.cr_return_amount > 100 THEN 'HIGH' ELSE 'LOW' END AS return_level,
       ii.max_promo_cost,
       cr.cr_returned_date_sk
   FROM catalog_returns cr
   JOIN item_inventory ii ON cr.cr_item_sk = ii.i_item_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN LATERAL (
        SELECT COUNT(*) AS promo_active_cnt
        FROM promotion p
        WHERE p.p_item_sk = ii.i_item_sk AND p.p_discount_active = 'Y'
   ) pl ON TRUE
   WHERE pl.promo_active_cnt > 0
     AND cr.cr_return_quantity > 0
),

web_ret AS (
   SELECT
       ii.i_item_id AS item_id,
       c.c_customer_id AS customer_id,
       wr.wr_return_amt AS return_amount,
       CASE WHEN wr.wr_return_amt > 100 THEN 'HIGH' ELSE 'LOW' END AS return_level,
       ii.max_promo_cost,
       wr.wr_returned_date_sk
   FROM web_returns wr
   JOIN item_inventory ii ON wr.wr_item_sk = ii.i_item_sk
   JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
   JOIN LATERAL (
        SELECT COUNT(*) AS promo_active_cnt
        FROM promotion p
        WHERE p.p_item_sk = ii.i_item_sk AND p.p_discount_active = 'Y'
   ) pl ON TRUE
   WHERE pl.promo_active_cnt > 0
     AND wr.wr_return_quantity > 0
)

SELECT
    item_id,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    SUM(DISTINCT return_amount) AS distinct_return_total,
    AVG(CASE WHEN return_level = 'HIGH' THEN return_amount END) AS avg_high_return,
    MAX(max_promo_cost) AS max_promo_cost
FROM (
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM web_ret
) u
GROUP BY item_id
ORDER BY distinct_return_total DESC
LIMIT 100
