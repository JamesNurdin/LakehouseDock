WITH joined_data AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sold_date_sk,
       d_sold.d_date,
       i.i_item_sk,
       i.i_product_name,
       i.i_brand,
       cs.cs_quantity,
       cs.cs_net_paid,
       cs.cs_net_profit,
       p.p_promo_id,
       cc.cc_call_center_id,
       sm.sm_ship_mode_id,
       ca_bill.ca_state AS bill_state,
       cd_bill.cd_gender,
       inv.inv_quantity_on_hand,
       s.s_store_id,
       ws.web_site_id,
       wp.wp_web_page_id,
       wr.wr_return_quantity,
       wr.wr_net_loss,
       cp.cp_catalog_page_id
   FROM catalog_sales cs
   JOIN date_dim d_sold
     ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_demographics cd_bill
     ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN customer_address ca_bill
     ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   LEFT JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN inventory inv
     ON i.i_item_sk = inv.inv_item_sk
    AND inv.inv_date_sk = d_sold.d_date_sk
   LEFT JOIN store s
     ON s.s_closed_date_sk = d_sold.d_date_sk
   LEFT JOIN web_site ws
     ON ws.web_open_date_sk = d_sold.d_date_sk
   LEFT JOIN web_returns wr
     ON cs.cs_order_number = wr.wr_order_number
    AND wr.wr_returned_date_sk = d_sold.d_date_sk
   LEFT JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE d_sold.d_year = 2000
     AND i.i_current_price > 50
     AND cs.cs_quantity > 5
     AND cc.cc_state = 'CA'
),
aggregated AS (
   SELECT
       i_brand,
       d_date,
       SUM(cs_quantity)               AS total_quantity,
       SUM(cs_net_paid)               AS total_paid,
       SUM(cs_net_profit)             AS total_profit,
       SUM(inv_quantity_on_hand)      AS total_inventory,
       SUM(wr_return_quantity)        AS total_returns,
       COUNT(DISTINCT cs_order_number) AS orders_cnt
   FROM joined_data
   GROUP BY i_brand, d_date
   HAVING SUM(cs_net_paid) > 1000
)
SELECT
    i_brand,
    d_date,
    total_quantity,
    total_paid,
    total_profit,
    total_inventory,
    total_returns,
    orders_cnt,
    SUM(total_paid) OVER (PARTITION BY i_brand ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_paid,
    RANK() OVER (PARTITION BY i_brand ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
WHERE i_brand IN (
    SELECT DISTINCT i_brand
    FROM item
    WHERE i_manufact LIKE 'es%'
)
UNION ALL
SELECT
    i_brand,
    d_date,
    total_quantity,
    total_paid,
    total_profit,
    total_inventory,
    total_returns,
    orders_cnt,
    SUM(total_paid) OVER (PARTITION BY i_brand ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_paid,
    RANK() OVER (PARTITION BY i_brand ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_discount_active = 'Y'
      AND p2.p_promo_id = (
          SELECT p3.p_promo_id
          FROM promotion p3
          WHERE p3.p_discount_active = 'Y'
          LIMIT 1
      )
)
ORDER BY i_brand, d_date DESC
LIMIT 100
