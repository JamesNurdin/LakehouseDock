WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        d.d_year,
        cc.cc_call_center_id,
        cp.cp_department,
        sm.sm_code,
        w.w_warehouse_id,
        w.w_country,
        p.p_promo_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = cs.cs_order_number
    LEFT JOIN web_returns wr ON wr.wr_order_number = cs.cs_order_number
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND w.w_country = 'United States'
      AND sm.sm_code = 'AIR'
),
high_profit_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cs.cs_net_profit > 5000
),
high_return_orders AS (
    SELECT cr.cr_order_number AS cs_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cr.cr_return_amount > 1000
),
intersect_orders AS (
    SELECT cs_order_number FROM high_profit_orders
    INTERSECT
    SELECT cs_order_number FROM high_return_orders
)
SELECT
    jd.w_warehouse_id,
    jd.cc_call_center_id,
    COUNT(DISTINCT jd.cs_order_number) AS high_profit_return_orders,
    SUM(jd.cs_net_profit) AS sum_profit,
    SUM(jd.cr_return_amount) AS sum_return_amount,
    AVG(jd.inv_quantity_on_hand) AS avg_inventory_on_hand
FROM joined_data jd
JOIN intersect_orders io ON jd.cs_order_number = io.cs_order_number
GROUP BY jd.w_warehouse_id, jd.cc_call_center_id
ORDER BY sum_profit DESC
LIMIT 100
