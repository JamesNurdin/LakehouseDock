WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ss.ss_sold_date_sk AS ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        cr.cr_return_amount,
        cr.cr_reason_sk,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        c.c_birth_country,
        sm.sm_type,
        st.s_store_name,
        cc.cc_name,
        ws.web_name,
        d.d_year
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_customer_sk = c.c_customer_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND st.s_division_id = 1
      AND c.c_birth_country = 'MONACO'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc = 'Damaged'
      AND inv.inv_quantity_on_hand > 500
)
SELECT
    d_year,
    s_store_name,
    cc_name,
    web_name,
    COUNT(DISTINCT cs_order_number) AS orders,
    SUM(cs_net_paid) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    AVG(cr_return_amount) AS avg_return_amount,
    MAX(inv_quantity_on_hand) AS max_inventory_on_hand
FROM sales_data
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = sales_data.cs_order_number
      AND cr2.cr_return_amount > 1000
)
GROUP BY d_year, s_store_name, cc_name, web_name
ORDER BY total_sales DESC
LIMIT 100
