WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_warehouse_sk
),
store_sales_agg AS (
    SELECT ss.ss_ticket_number,
           ss.ss_item_sk,
           ss.ss_customer_sk,
           ss.ss_hdemo_sk,
           SUM(ss.ss_net_paid) AS store_net_paid,
           COUNT(*) AS store_txn_count
    FROM store_sales ss
    WHERE ss.ss_sales_price > 150.00
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
      )
    GROUP BY ss.ss_ticket_number, ss.ss_item_sk, ss.ss_customer_sk, ss.ss_hdemo_sk
)
SELECT
    w.w_warehouse_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    r.r_reason_desc,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ssa.store_net_paid) AS total_store_net_paid,
    SUM(i.total_qty_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS num_bill_customers,
    COUNT(DISTINCT ssa.ss_customer_sk) AS num_store_customers,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    SUM(sr.sr_return_amt) AS total_return_amount,
    (SUM(cs.cs_net_paid) + SUM(ssa.store_net_paid)) AS total_combined_net_paid,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY (SUM(cs.cs_net_paid) + SUM(ssa.store_net_paid)) DESC) AS sales_rank
FROM catalog_sales cs
FULL OUTER JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN inv_agg i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_sales ss
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_sales_agg ssa
    ON ssa.ss_ticket_number = ss.ss_ticket_number
   AND ssa.ss_item_sk = ss.ss_item_sk
   AND ssa.ss_customer_sk = ss.ss_customer_sk
   AND ssa.ss_hdemo_sk = ss.ss_hdemo_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
WHERE
    cs.cs_quantity > 5
    AND cs.cs_net_paid > 100.00
    AND cs.cs_sold_date_sk BETWEEN 2451910 AND 2451920
    AND hd.hd_dep_count <= 3
    AND hd.hd_buy_potential = '501-1000'
    AND ib.ib_lower_bound >= 50001
    AND w.w_state = 'CA'
    AND i.total_qty_on_hand >= 1000
    AND r.r_reason_desc LIKE '%damaged%'
GROUP BY
    w.w_warehouse_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    r.r_reason_desc
ORDER BY total_combined_net_paid DESC
LIMIT 100
