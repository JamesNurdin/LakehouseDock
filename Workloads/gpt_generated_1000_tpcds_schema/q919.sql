WITH cs_agg AS (
   SELECT
       cs.cs_item_sk,
       cs.cs_sold_date_sk,
       cs.cs_promo_sk,
       cs.cs_bill_customer_sk,
       cs.cs_sold_time_sk,
       SUM(cs.cs_net_profit)            AS total_cs_profit,
       COUNT(*)                         AS cs_cnt
   FROM catalog_sales cs
   WHERE cs.cs_wholesale_cost > 30
     AND cs.cs_quantity BETWEEN 1 AND 10
     AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450900
   GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk, cs.cs_promo_sk, cs.cs_bill_customer_sk, cs.cs_sold_time_sk
),
sr_agg AS (
   SELECT
       sr.sr_item_sk,
       sr.sr_returned_date_sk,
       sr.sr_reason_sk,
       sr.sr_return_time_sk,
       sr.sr_customer_sk,
       SUM(sr.sr_net_loss)               AS total_sr_loss,
       COUNT(*)                          AS sr_cnt
   FROM store_returns sr
   WHERE sr.sr_return_quantity > 0
     AND sr.sr_fee > 10
   GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk, sr.sr_reason_sk, sr.sr_return_time_sk, sr.sr_customer_sk
),
unioned AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       p.p_promo_name,
       td.t_sub_shift,
       CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
       cs.total_cs_profit                         AS metric,
       'catalog'                                   AS src,
       (SELECT SUM(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk) AS total_inventory_qty
   FROM cs_agg cs
   JOIN customer cu      ON cs.cs_bill_customer_sk = cu.c_customer_sk
   JOIN item i           ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p      ON cs.cs_promo_sk = p.p_promo_sk
   JOIN time_dim td      ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN inventory inv    ON i.i_item_sk = inv.inv_item_sk
   JOIN web_sales ws     ON cs.cs_item_sk = ws.ws_item_sk
                           AND cs.cs_sold_time_sk = ws.ws_sold_time_sk
                           AND cs.cs_promo_sk = ws.ws_promo_sk
   JOIN web_page wp      ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
                           AND td.t_time_sk = sr.sr_return_time_sk
   JOIN reason r         ON sr.sr_reason_sk = r.r_reason_sk
   WHERE p.p_discount_active = 'Y'
     AND td.t_sub_shift = 'evening'
     AND i.i_brand = 'Brand#12'
     AND i.i_category = 'Electronics'
   UNION DISTINCT
   SELECT
       i.i_item_id,
       i.i_product_name,
       p.p_promo_name,
       td.t_sub_shift,
       CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
       -sr.total_sr_loss                         AS metric,
       'store_return'                             AS src,
       (SELECT SUM(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk) AS total_inventory_qty
   FROM sr_agg sr
   JOIN customer cu      ON sr.sr_customer_sk = cu.c_customer_sk
   JOIN item i           ON sr.sr_item_sk = i.i_item_sk
   JOIN promotion p      ON i.i_item_sk = p.p_item_sk
   JOIN time_dim td      ON sr.sr_return_time_sk = td.t_time_sk
   JOIN inventory inv    ON i.i_item_sk = inv.inv_item_sk
   JOIN web_sales ws     ON i.i_item_sk = ws.ws_item_sk
                           AND td.t_time_sk = ws.ws_sold_time_sk
   JOIN web_page wp      ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN reason r         ON sr.sr_reason_sk = r.r_reason_sk
   WHERE r.r_reason_desc = 'Damaged'
     AND td.t_sub_shift = 'afternoon'
     AND i.i_brand = 'Brand#12'
     AND i.i_category = 'Electronics'
     AND sr.total_sr_loss > 100
)
SELECT
   u.i_item_id,
   u.i_product_name,
   u.promo_status,
   u.t_sub_shift,
   u.metric,
   u.src,
   u.total_inventory_qty,
   ROW_NUMBER() OVER (ORDER BY u.metric DESC) AS rn
FROM unioned u
WHERE u.i_item_id NOT IN (
   SELECT i_ex.i_item_id FROM item i_ex WHERE i_ex.i_brand_id = 999
   EXCEPT
   SELECT i_ex2.i_item_id FROM item i_ex2 WHERE i_ex2.i_category = 'Toys'
)
ORDER BY u.metric DESC
LIMIT 100
