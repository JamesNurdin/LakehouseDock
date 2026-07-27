WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_cdemo_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_description,
        sm.sm_type,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        p.p_promo_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_net_paid_inc_tax > 1000
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND cp.cp_department = 'Books'
      AND sm.sm_type = 'AIR'
),
agg_data AS (
    SELECT
        sd.w_warehouse_sk        AS warehouse_sk,
        sd.w_warehouse_name,
        sd.cp_department,
        sd.p_promo_name,
        sd.cs_sold_time_sk,
        SUM(sd.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        AVG(sd.cs_net_profit)        AS avg_net_profit,
        SUM(sd.cs_net_profit)        AS sum_net_profit
    FROM sales_data sd
    GROUP BY
        sd.w_warehouse_sk,
        sd.w_warehouse_name,
        sd.cp_department,
        sd.p_promo_name,
        sd.cs_sold_time_sk
    HAVING SUM(sd.cs_net_paid_inc_tax) > 5000
)
SELECT
    a.w_warehouse_name,
    a.cp_department,
    a.p_promo_name,
    a.total_net_paid_inc_tax,
    a.avg_net_profit,
    CASE WHEN a.sum_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY a.w_warehouse_name ORDER BY a.total_net_paid_inc_tax DESC) AS warehouse_rank,
    inv.inv_quantity_on_hand,
    sr.sr_return_amt,
    cd2.cd_education_status
FROM agg_data a
-- join back to warehouse to satisfy the inventory join rule
JOIN warehouse w2 ON a.warehouse_sk = w2.w_warehouse_sk
-- inventory linked through warehouse
JOIN inventory inv ON inv.inv_warehouse_sk = w2.w_warehouse_sk
-- time dimension for linking sales time to returns
JOIN time_dim t_ret ON a.cs_sold_time_sk = t_ret.t_time_sk
-- store returns linked through the same time_dim row
JOIN store_returns sr ON sr.sr_return_time_sk = t_ret.t_time_sk
-- customer demographics for the return customer
JOIN customer_demographics cd2 ON sr.sr_cdemo_sk = cd2.cd_demo_sk
WHERE inv.inv_quantity_on_hand > 0
  AND sr.sr_return_amt > 0
  AND cd2.cd_credit_rating = 'A'
  AND t_ret.t_hour BETWEEN 9 AND 17
LIMIT 100
