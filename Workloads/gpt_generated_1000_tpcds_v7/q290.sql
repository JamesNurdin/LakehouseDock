WITH agg_sales AS (
  SELECT
    bcust.c_customer_id AS bill_customer_id,
    bcust.c_preferred_cust_flag AS preferred_flag,
    i.i_category AS item_category,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    AVG(cs.cs_quantity) AS avg_quantity
  FROM catalog_sales cs
  JOIN customer bcust
    ON cs.cs_bill_customer_sk = bcust.c_customer_sk
  JOIN customer scust
    ON cs.cs_ship_customer_sk = scust.c_customer_sk
  JOIN customer_demographics bcdemo
    ON cs.cs_bill_cdemo_sk = bcdemo.cd_demo_sk
  JOIN customer_demographics scdemo
    ON cs.cs_ship_cdemo_sk = scdemo.cd_demo_sk
  JOIN household_demographics bhdemo
    ON cs.cs_bill_hdemo_sk = bhdemo.hd_demo_sk
  JOIN household_demographics shdemo
    ON cs.cs_ship_hdemo_sk = shdemo.hd_demo_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN customer_demographics cd_cur
    ON bcust.c_current_cdemo_sk = cd_cur.cd_demo_sk
  JOIN household_demographics hd_cur
    ON bcust.c_current_hdemo_sk = hd_cur.hd_demo_sk
  WHERE i.i_category IS NOT NULL
  GROUP BY
    bcust.c_customer_id,
    bcust.c_preferred_cust_flag,
    i.i_category
)
SELECT
  bill_customer_id,
  preferred_flag,
  item_category,
  total_net_profit,
  order_cnt,
  avg_quantity,
  ROW_NUMBER() OVER (PARTITION BY bill_customer_id ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY total_net_profit DESC
LIMIT 100
