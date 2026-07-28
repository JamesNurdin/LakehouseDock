WITH sales_enriched AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        i.i_item_id,
        i.i_category,
        i.i_category_id,
        i.i_brand,
        p.p_promo_name,
        sm.sm_type AS ship_type,
        w.w_warehouse_name,
        hd_bill.hd_vehicle_count AS bill_vehicle_cnt,
        hd_ship.hd_vehicle_count AS ship_vehicle_cnt,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cp.cp_department = 'Books'
      AND i.i_category_id IN (5, 10)
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
      AND cs.cs_quantity > 5
      AND cs.cs_net_profit > 0
      AND hd_bill.hd_vehicle_count >= 0
)
SELECT
    se.cs_order_number,
    se.cp_department,
    se.i_category,
    se.i_item_id,
    se.cs_quantity,
    se.cs_net_profit,
    CASE
        WHEN se.cs_net_profit > 100 THEN 'High'
        WHEN se.cs_net_profit > 20  THEN 'Medium'
        ELSE 'Low'
    END AS profit_level,
    COALESCE(wr.wr_fee, 0) AS return_fee,
    ROW_NUMBER() OVER (
        PARTITION BY se.cp_department, se.i_category
        ORDER BY se.cs_net_profit DESC
    ) AS profit_rank
FROM sales_enriched se
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = se.cs_item_sk
WHERE (wr.wr_fee > 20 OR wr.wr_fee IS NULL)
ORDER BY profit_rank ASC, se.cs_net_profit DESC
LIMIT 100
