WITH sub_bahrain AS (
    SELECT
        w.w_warehouse_name,
        ib1.ib_upper_bound AS bill_income_upper,
        ib2.ib_upper_bound AS ship_income_upper,
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    JOIN customer AS bill_c ON cs.cs_bill_customer_sk = bill_c.c_customer_sk
    JOIN customer AS ship_c ON cs.cs_ship_customer_sk = ship_c.c_customer_sk
    JOIN household_demographics AS bill_hd ON cs.cs_bill_hdemo_sk = bill_hd.hd_demo_sk
    JOIN household_demographics AS ship_hd ON cs.cs_ship_hdemo_sk = ship_hd.hd_demo_sk
    JOIN warehouse AS w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics AS bill_hd_current ON bill_c.c_current_hdemo_sk = bill_hd_current.hd_demo_sk
    JOIN household_demographics AS ship_hd_current ON ship_c.c_current_hdemo_sk = ship_hd_current.hd_demo_sk
    JOIN income_band AS ib1 ON bill_hd.hd_income_band_sk = ib1.ib_income_band_sk
    JOIN income_band AS ib2 ON ship_hd.hd_income_band_sk = ib2.ib_income_band_sk
    WHERE bill_c.c_birth_country = 'BAHRAIN'
),
sub_japan AS (
    SELECT
        w.w_warehouse_name,
        ib1.ib_upper_bound AS bill_income_upper,
        ib2.ib_upper_bound AS ship_income_upper,
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    JOIN customer AS bill_c ON cs.cs_bill_customer_sk = bill_c.c_customer_sk
    JOIN customer AS ship_c ON cs.cs_ship_customer_sk = ship_c.c_customer_sk
    JOIN household_demographics AS bill_hd ON cs.cs_bill_hdemo_sk = bill_hd.hd_demo_sk
    JOIN household_demographics AS ship_hd ON cs.cs_ship_hdemo_sk = ship_hd.hd_demo_sk
    JOIN warehouse AS w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics AS bill_hd_current ON bill_c.c_current_hdemo_sk = bill_hd_current.hd_demo_sk
    JOIN household_demographics AS ship_hd_current ON ship_c.c_current_hdemo_sk = ship_hd_current.hd_demo_sk
    JOIN income_band AS ib1 ON bill_hd.hd_income_band_sk = ib1.ib_income_band_sk
    JOIN income_band AS ib2 ON ship_hd.hd_income_band_sk = ib2.ib_income_band_sk
    WHERE ship_c.c_birth_country = 'JAPAN'
)
SELECT
    combined.w_warehouse_name,
    combined.bill_income_upper,
    combined.ship_income_upper,
    COUNT(DISTINCT combined.cs_order_number) AS order_cnt,
    SUM(combined.cs_net_paid_inc_ship) AS total_net_paid,
    AVG(combined.cs_ext_discount_amt) AS avg_discount
FROM (
    SELECT * FROM sub_bahrain
    UNION ALL
    SELECT * FROM sub_japan
) AS combined
GROUP BY combined.w_warehouse_name, combined.bill_income_upper, combined.ship_income_upper
HAVING SUM(combined.cs_net_paid_inc_ship) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
