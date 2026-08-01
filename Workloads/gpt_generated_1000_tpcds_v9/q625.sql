WITH sales_detail AS (
    SELECT DISTINCT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_quantity,
        cc.cc_name,
        cc.cc_state,
        i.i_category,
        i.i_current_price,
        p.p_promo_name,
        p.p_discount_active,
        tp.t_hour,
        tp.t_meal_time,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        inv.inv_quantity_on_hand,
        cust_bill.c_birth_month
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim tp ON cs.cs_sold_time_sk = tp.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE tp.t_hour = 13
      AND cust_bill.c_birth_month = 11
      AND inv.inv_quantity_on_hand > 50
      AND cs.cs_quantity >= 2
)
SELECT
    cc_name,
    i_category,
    t_meal_time,
    ib_lower_bound,
    ib_upper_bound,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    MIN(cs_net_profit) AS min_profit,
    MAX(cs_net_profit) AS max_profit
FROM sales_detail
GROUP BY cc_name, i_category, t_meal_time, ib_lower_bound, ib_upper_bound
HAVING SUM(cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
