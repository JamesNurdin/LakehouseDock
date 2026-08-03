WITH agg_returns AS (
   SELECT
       cr_item_sk,
       cr_returned_time_sk,
       cr_refunded_addr_sk,
       cr_refunded_customer_sk,
       SUM(cr_return_quantity) AS total_return_qty,
       SUM(cr_return_amount)   AS total_return_amount,
       SUM(cr_net_loss)        AS total_net_loss
   FROM catalog_returns
   WHERE cr_return_amount > 100
     AND cr_return_ship_cost < 500
     AND cr_return_quantity >= 1
   GROUP BY cr_item_sk, cr_returned_time_sk, cr_refunded_addr_sk, cr_refunded_customer_sk
),
item_inventory AS (
   SELECT
       i.i_item_sk,
       i.i_item_id,
       i.i_product_name,
       inv.inv_quantity_on_hand
   FROM inventory inv
   RIGHT OUTER JOIN item i
       ON inv.inv_item_sk = i.i_item_sk
)
SELECT DISTINCT
    ii.i_item_id,
    ii.i_product_name,
    t.t_time,
    t.t_hour,
    ca.ca_state,
    c.c_customer_id,
    agg.total_return_qty,
    agg.total_return_amount,
    agg.total_net_loss,
    ii.inv_quantity_on_hand,
    CASE
        WHEN agg.total_return_amount > 1000 THEN 'HIGH'
        WHEN agg.total_return_amount > 500  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_level,
    ROW_NUMBER() OVER (PARTITION BY ii.i_item_id ORDER BY agg.total_net_loss DESC) AS rn_item,
    RANK()        OVER (PARTITION BY ca.ca_state   ORDER BY agg.total_return_amount DESC) AS state_return_rank
FROM agg_returns agg
JOIN time_dim t
    ON agg.cr_returned_time_sk = t.t_time_sk
JOIN customer_address ca
    ON agg.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer c
    ON agg.cr_refunded_customer_sk = c.c_customer_sk
JOIN item_inventory ii
    ON agg.cr_item_sk = ii.i_item_sk
WHERE t.t_hour BETWEEN 8 AND 17
  AND ca.ca_state = 'CA'
  AND (ii.inv_quantity_on_hand IS NULL OR ii.inv_quantity_on_hand > 0)
  AND t.t_sub_shift = 'morning'
  AND t.t_second < 20
ORDER BY agg.total_net_loss DESC, rn_item
LIMIT 100
