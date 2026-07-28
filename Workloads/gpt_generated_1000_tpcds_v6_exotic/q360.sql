WITH sales_join AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_description,
        hd.hd_income_band_sk,
        ca.ca_city,
        sm.sm_ship_mode_id,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
        ) AS avg_return_amount,
        EXISTS (
            SELECT 1
            FROM catalog_returns cr3
            WHERE cr3.cr_order_number = cs.cs_order_number
              AND cr3.cr_return_amount > 100
        ) AS has_large_return
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE hd.hd_income_band_sk >= 15
      AND regexp_like(cp.cp_description, '(?i)women|men')
      AND ca.ca_city LIKE 'San%'
)
SELECT
    cp_department,
    profit_flag,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_net_paid) AS total_paid,
    SUM(cs_net_profit) AS total_profit,
    AVG(avg_return_amount) AS avg_return_amount,
    SUM(CASE WHEN has_large_return THEN 1 ELSE 0 END) AS orders_with_large_return
FROM sales_join
GROUP BY cp_department, profit_flag
HAVING SUM(cs_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
