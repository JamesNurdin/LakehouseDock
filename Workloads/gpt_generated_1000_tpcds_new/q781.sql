WITH sales_pre AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        SUM(cs.cs_ext_sales_price)      AS sales_amt,
        SUM(cs.cs_net_profit)           AS profit_amt,
        COUNT(*)                        AS sales_cnt,
        SUM(cs.cs_quantity)             AS total_quantity
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451175
    GROUP BY
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk
)
SELECT
    cc.cc_name                     AS call_center_name,
    sm.sm_ship_mode_id              AS ship_mode_id,
    ib.ib_income_band_sk            AS income_band_sk,
    SUM(s.sales_amt)                AS total_sales,
    SUM(s.profit_amt)               AS total_profit,
    COUNT(DISTINCT s.cs_order_number) AS order_count,
    MIN(s.sales_amt)                AS min_sales,
    MAX(s.sales_amt)                AS max_sales
FROM sales_pre s
FULL OUTER JOIN catalog_returns r
        ON s.cs_order_number = r.cr_order_number
JOIN call_center cc
        ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
        ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
        ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c
        ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN reason rsn
        ON r.cr_reason_sk = rsn.r_reason_sk
WHERE s.total_quantity > 5
  AND cc.cc_state = 'TX'
  AND w.w_zip = '36098'
  AND sm.sm_contract = '6Hzzp4JkzjqD8MGXLCDa'
  AND cd.cd_gender = 'M'
  AND ib.ib_upper_bound >= 50000
  AND ca.ca_state = 'CA'
  AND NOT EXISTS (
        SELECT 1 FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = r.cr_ship_mode_sk
          AND sm2.sm_contract = 'OrDuVy2H'
    )
GROUP BY ROLLUP (cc.cc_name, sm.sm_ship_mode_id, ib.ib_income_band_sk)

UNION DISTINCT

SELECT
    cc.cc_name                     AS call_center_name,
    sm.sm_ship_mode_id              AS ship_mode_id,
    ib.ib_income_band_sk            AS income_band_sk,
    SUM(s.sales_amt)                AS total_sales,
    SUM(s.profit_amt)               AS total_profit,
    COUNT(DISTINCT s.cs_order_number) AS order_count,
    MIN(s.sales_amt)                AS min_sales,
    MAX(s.sales_amt)                AS max_sales
FROM sales_pre s
FULL OUTER JOIN catalog_returns r
        ON s.cs_order_number = r.cr_order_number
JOIN call_center cc
        ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
        ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
        ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c
        ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN reason rsn
        ON r.cr_reason_sk = rsn.r_reason_sk
WHERE s.total_quantity <= 5
  AND cc.cc_state = 'TX'
  AND w.w_zip = '36098'
  AND sm.sm_contract = '6Hzzp4JkzjqD8MGXLCDa'
  AND cd.cd_gender = 'M'
  AND ib.ib_upper_bound >= 50000
  AND ca.ca_state = 'CA'
  AND NOT EXISTS (
        SELECT 1 FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = r.cr_ship_mode_sk
          AND sm2.sm_contract = 'OrDuVy2H'
    )
GROUP BY ROLLUP (cc.cc_name, sm.sm_ship_mode_id, ib.ib_income_band_sk)

ORDER BY total_sales DESC, call_center_name NULLS LAST, ship_mode_id NULLS LAST, income_band_sk NULLS LAST
LIMIT 100
