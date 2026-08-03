WITH first_raw AS (
    SELECT
        i.i_brand,
        i.i_category,
        cs.cs_net_paid AS total_sales,
        cs.cs_net_profit AS total_profit,
        cu.c_customer_id,
        CASE WHEN cu.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
        cs.cs_quantity,
        cs.cs_sold_date_sk
    FROM
        tpcds.call_center cc
        JOIN tpcds.catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN tpcds.customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
        JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
        JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
        JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
        cc.cc_state = 'CA'
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
        AND i.i_brand = 'Brand#12'
        AND hd.hd_buy_potential = '1001-5000'
        AND ib.ib_upper_bound > 60000
        AND inv.inv_quantity_on_hand > 500
        AND cu.c_preferred_cust_flag = 'Y'
        AND sm.sm_type = 'AIR'
        AND NOT EXISTS (
            SELECT 1 FROM tpcds.web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk
        )
),
second_raw AS (
    SELECT
        i.i_brand,
        i.i_category,
        cs.cs_net_paid AS total_sales,
        cs.cs_net_profit AS total_profit,
        cu.c_customer_id,
        CASE WHEN cu.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_type,
        cs.cs_quantity,
        cs.cs_sold_date_sk
    FROM
        tpcds.call_center cc
        JOIN tpcds.catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN tpcds.customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
        JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
        JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
        JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
        cc.cc_state = 'CA'
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
        AND i.i_brand = 'Brand#23'
        AND hd.hd_buy_potential = '1001-5000'
        AND ib.ib_upper_bound > 60000
        AND inv.inv_quantity_on_hand > 500
        AND cu.c_preferred_cust_flag = 'Y'
        AND sm.sm_type = 'AIR'
        AND NOT EXISTS (
            SELECT 1 FROM tpcds.web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk
        )
),
combined AS (
    SELECT * FROM first_raw
    UNION
    SELECT * FROM second_raw
)
SELECT
    i_brand,
    i_category,
    customer_type,
    SUM(total_sales) AS total_sales,
    SUM(total_profit) AS total_profit,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    AVG(cs_quantity) AS avg_quantity,
    MIN(cs_sold_date_sk) AS first_sold_date_sk
FROM
    combined
GROUP BY
    i_brand,
    i_category,
    customer_type
HAVING
    SUM(total_sales) > 10000
ORDER BY
    total_sales DESC
