WITH joined AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_id,
    w.w_warehouse_name,
    cd.cd_gender,
    cs.cs_net_profit,
    ss.ss_net_profit,
    wr.wr_net_loss,
    cs.cs_order_number,
    cs.cs_ext_discount_amt
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                     AND ss.ss_cdemo_sk = cd.cd_demo_sk
                     AND ss.ss_promo_sk = p.p_promo_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                     AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                     AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    AND p.p_channel_radio = 'N'
    AND cd.cd_purchase_estimate >= 5000
    AND inv.inv_quantity_on_hand > 0
    AND wr.wr_return_amt > 100
),
agg AS (
  SELECT
    i_item_id,
    i_product_name,
    p_promo_id,
    w_warehouse_name,
    cd_gender,
    SUM(cs_net_profit) AS total_catalog_profit,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(wr_net_loss) AS total_return_loss,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(cs_ext_discount_amt) AS avg_discount,
    CASE WHEN SUM(cs_net_profit) + SUM(ss_net_profit) - SUM(wr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
  FROM joined
  GROUP BY i_item_id, i_product_name, p_promo_id, w_warehouse_name, cd_gender
)
SELECT
  i_item_id,
  i_product_name,
  p_promo_id,
  w_warehouse_name,
  cd_gender,
  total_catalog_profit,
  total_store_profit,
  total_return_loss,
  distinct_orders,
  avg_discount,
  profit_level,
  SUM(total_catalog_profit + total_store_profit - total_return_loss) OVER (PARTITION BY i_item_id ORDER BY total_catalog_profit DESC) AS cumulative_profit_by_item
FROM agg
ORDER BY total_catalog_profit DESC
LIMIT 100
