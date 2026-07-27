WITH sales_data AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    i.i_category,
    i.i_brand,
    w.w_warehouse_name,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    ss.ss_store_sk,
    ss.ss_quantity AS ss_quantity,
    ss.ss_net_profit AS ss_net_profit,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    inv.inv_quantity_on_hand,
    st.s_store_name,
    td.t_hour
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN store st ON ss.ss_store_sk = st.s_store_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
      AND sr.sr_return_time_sk = td.t_time_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
),
agg AS (
  SELECT
    i_category,
    i_brand,
    w_warehouse_name,
    s_store_name,
    cd_gender,
    ib_lower_bound,
    ib_upper_bound,
    SUM(cs_net_profit) AS total_catalog_net_profit,
    SUM(ss_net_profit) AS total_store_net_profit,
    SUM(COALESCE(sr_return_amt, 0)) AS total_store_return_amount,
    SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_return_amount,
    AVG(COALESCE(inv_quantity_on_hand, 0)) AS avg_inventory_qty
  FROM sales_data
  GROUP BY
    i_category,
    i_brand,
    w_warehouse_name,
    s_store_name,
    cd_gender,
    ib_lower_bound,
    ib_upper_bound
)
SELECT
  a.*, 
  ROW_NUMBER() OVER (PARTITION BY a.i_category ORDER BY a.total_catalog_net_profit DESC) AS category_rank
FROM agg a
ORDER BY a.total_catalog_net_profit DESC
LIMIT 100
