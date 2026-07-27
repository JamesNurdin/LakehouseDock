WITH sales_agg AS (
   SELECT
       d.d_year,
       c.cd_gender,
       h.hd_buy_potential,
       w.w_warehouse_name,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_quantity) AS total_quantity,
       SUM(ss.ss_net_profit) AS total_net_profit,
       AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_demographics c ON ss.ss_cdemo_sk = c.cd_demo_sk
   JOIN household_demographics h ON ss.ss_hdemo_sk = h.hd_demo_sk
   JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
     AND inv.inv_quantity_on_hand > 100
     AND h.hd_buy_potential = '1001-5000'
     AND EXISTS (
         SELECT 1 FROM call_center cc2
         WHERE cc2.cc_state = 'CA'
           AND cc2.cc_closed_date_sk = d.d_date_sk
     )
   GROUP BY d.d_year, c.cd_gender, h.hd_buy_potential, w.w_warehouse_name
)
SELECT
    profit_category,
    AVG(total_net_paid) AS avg_net_paid,
    SUM(total_quantity) AS sum_quantity,
    AVG(avg_qty_on_hand) AS avg_inventory_on_hand
FROM (
    SELECT
        sa.d_year,
        sa.cd_gender,
        sa.hd_buy_potential,
        sa.w_warehouse_name,
        CASE 
            WHEN sa.total_net_profit > 10000 THEN 'HIGH'
            WHEN sa.total_net_profit BETWEEN 0 AND 10000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category,
        sa.total_net_paid,
        sa.total_quantity,
        sa.avg_qty_on_hand
    FROM sales_agg sa
    WHERE sa.total_net_paid > 50000
) sub
GROUP BY profit_category
HAVING AVG(total_net_paid) > 60000
ORDER BY avg_net_paid DESC
LIMIT 100
