WITH
sr_items AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        i.i_product_name AS return_product_name
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
),
sr_agg AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
    HAVING SUM(sr.sr_return_amt_inc_tax) > 100
)
SELECT
    cs.cs_order_number,
    i1.i_product_name AS sold_product_name,
    i3.i_product_name AS sold_product_name_dup,
    sm1.sm_type AS ship_mode_type,
    sm2.sm_type AS ship_mode_type_dup,
    w1.w_warehouse_name AS warehouse_name,
    w2.w_city AS warehouse_city,
    cs.cs_quantity,
    cs.cs_net_paid_inc_ship_tax,
    si1.return_product_name AS return_product_name_1,
    si2.return_product_name AS return_product_name_2,
    sr_agg.total_return_amt,
    sr_agg.total_net_loss,
    (SELECT MAX(cs_sub.cs_list_price)
     FROM catalog_sales cs_sub
     WHERE cs_sub.cs_item_sk = cs.cs_item_sk) AS max_list_price
FROM catalog_sales cs
JOIN ship_mode sm1
  ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN ship_mode sm2
  ON cs.cs_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN warehouse w1
  ON cs.cs_warehouse_sk = w1.w_warehouse_sk
JOIN warehouse w2
  ON cs.cs_warehouse_sk = w2.w_warehouse_sk
JOIN item i1
  ON cs.cs_item_sk = i1.i_item_sk
JOIN item i3
  ON cs.cs_item_sk = i3.i_item_sk
JOIN sr_items si1
  ON si1.sr_item_sk = cs.cs_item_sk
JOIN sr_items si2
  ON si2.sr_item_sk = cs.cs_item_sk
JOIN sr_agg
  ON sr_agg.sr_item_sk = cs.cs_item_sk
LIMIT 100
