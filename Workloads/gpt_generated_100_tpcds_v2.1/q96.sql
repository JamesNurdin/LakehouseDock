WITH sales_data AS (
    SELECT
        cp.cp_department AS cp_department,
        i.i_brand AS i_brand,
        hd_bill.hd_buy_potential AS hd_buy_potential,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
       AND ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_number BETWEEN 5 AND 15
      AND i.i_current_price > 150.00
      AND hd_bill.hd_buy_potential = '>10000'
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    cp_department,
    i_brand,
    hd_buy_potential,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    SUM(ss_net_paid) AS total_store_net_paid,
    SUM(cs_net_profit) + SUM(ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ss_ticket_number) AS store_ticket_cnt,
    SUM(CASE WHEN inv_quantity_on_hand > 100 THEN cs_net_paid ELSE 0 END) AS net_paid_high_stock
FROM sales_data
GROUP BY cp_department, i_brand, hd_buy_potential
ORDER BY (total_catalog_net_paid + total_store_net_paid) DESC
LIMIT 100
