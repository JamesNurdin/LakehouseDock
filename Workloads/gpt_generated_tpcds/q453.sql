WITH high_buy_potential_sales AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = 'HIGH'
)
SELECT
    cc.cc_call_center_id,
    cc.cc_state,
    sm.sm_ship_mode_id,
    sm.sm_type,
    i.i_category,
    sum(hb.cs_ext_sales_price) AS total_sales,
    sum(hb.cs_net_profit) AS total_profit,
    avg(hb.cs_ext_discount_amt) AS avg_discount_amount,
    count(DISTINCT hb.cs_bill_customer_sk) AS distinct_customers,
    sum(hb.cs_quantity) AS total_quantity
FROM high_buy_potential_sales hb
JOIN call_center cc
    ON hb.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON hb.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON hb.cs_item_sk = i.i_item_sk
GROUP BY cc.cc_call_center_id, cc.cc_state, sm.sm_ship_mode_id, sm.sm_type, i.i_category
ORDER BY total_profit DESC
LIMIT 10
