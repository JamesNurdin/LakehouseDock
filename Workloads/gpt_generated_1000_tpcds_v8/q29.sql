WITH sales_agg AS (
    SELECT
        c.cc_call_center_id,
        sm.sm_type,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM
        catalog_sales cs
        JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
        JOIN time_dim td_ret ON sr.sr_return_time_sk = td_ret.t_time_sk
    WHERE
        c.cc_state = 'CA'
        AND i.i_current_price BETWEEN 20 AND 100
        AND hd.hd_income_band_sk IN (8, 10, 16)
        AND sm.sm_type = 'AIR'
        AND w.w_state = 'CA'
        AND cs.cs_quantity > 30
        AND cs.cs_list_price > 50
        AND cs.cs_ext_discount_amt < 5
        AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2455849
    GROUP BY
        c.cc_call_center_id,
        sm.sm_type
)
SELECT
    cc_call_center_id,
    sm_type,
    total_profit,
    total_sales,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    orders,
    avg_quantity
FROM
    sales_agg
WHERE
    total_profit > (
        SELECT AVG(cs_net_profit)
        FROM catalog_sales
        WHERE cs_quantity > 50
    )
ORDER BY
    total_profit DESC
LIMIT 100
