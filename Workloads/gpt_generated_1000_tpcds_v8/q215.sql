WITH sampled_sales AS (
   SELECT *
   FROM catalog_sales
   TABLESAMPLE BERNOULLI (10)
),
sales_with_joins AS (
   SELECT
       ss.cs_sold_date_sk,
       ss.cs_sold_time_sk,
       ss.cs_item_sk,
       ss.cs_warehouse_sk,
       ss.cs_quantity,
       ss.cs_net_profit,
       ss.cs_ext_sales_price,
       i.i_item_id,
       i.i_class_id,
       i.i_manufact,
       i.i_category,
       w.w_warehouse_name,
       w.w_city,
       t.t_hour,
       t.t_minute,
       ca.ca_state,
       cd.cd_gender,
       hd.hd_income_band_sk,
       inv.inv_quantity_on_hand,
       COALESCE(wr.wr_return_quantity, 0) AS return_qty,
       COALESCE(wr.wr_return_amt, 0) AS return_amt
   FROM sampled_sales ss
   JOIN item i
     ON ss.cs_item_sk = i.i_item_sk
   JOIN warehouse w
     ON ss.cs_warehouse_sk = w.w_warehouse_sk
   JOIN time_dim t
     ON ss.cs_sold_time_sk = t.t_time_sk
   JOIN customer_address ca
     ON ss.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd
     ON ss.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON ss.cs_bill_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN inventory inv
     ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_returns wr
     ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
   WHERE i.i_class_id = 15
     AND i.i_manufact = 'callyeingeing'
     AND t.t_hour BETWEEN 8 AND 12
     AND ca.ca_state = 'CA'
     AND w.w_warehouse_sq_ft > 20000
)
SELECT
   swj.cs_sold_date_sk,
   swj.i_item_id,
   swj.i_category,
   swj.w_warehouse_name,
   SUM(swj.cs_quantity) AS total_quantity_sold,
   SUM(swj.cs_net_profit) AS total_net_profit,
   SUM(swj.return_qty) AS total_return_qty,
   SUM(swj.return_amt) AS total_return_amt,
   AVG(swj.inv_quantity_on_hand) AS avg_inventory_on_hand,
   ROW_NUMBER() OVER (PARTITION BY swj.i_item_id ORDER BY SUM(swj.cs_net_profit) DESC) AS profit_rank,
   CASE
       WHEN SUM(swj.cs_net_profit) > 50000 THEN 'HIGH'
       WHEN SUM(swj.cs_net_profit) > 20000 THEN 'MEDIUM'
       ELSE 'LOW'
   END AS profit_category
FROM sales_with_joins swj
GROUP BY
   swj.cs_sold_date_sk,
   swj.i_item_id,
   swj.i_category,
   swj.w_warehouse_name
HAVING SUM(swj.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
OFFSET 0 FETCH NEXT 50 ROWS ONLY
