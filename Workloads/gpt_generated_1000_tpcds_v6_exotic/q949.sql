WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_sold_time_sk,
        sm.sm_carrier,
        ca.ca_county,
        ib.ib_lower_bound,
        p.p_promo_name,
        w.w_warehouse_name,
        cd.cd_gender,
        sr.sr_return_amt
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON td.t_time_sk = sr.sr_return_time_sk
    WHERE ca.ca_county = 'Madison County'
      AND sm.sm_carrier = 'USPS'
      AND ib.ib_lower_bound >= 50000
      AND p.p_promo_name = 'Summer Sale'
)
SELECT
    sm_carrier,
    ca_county,
    ib_lower_bound,
    w_warehouse_name,
    cd_gender,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cs_ext_discount_amt) AS total_discount,
    SUM(COALESCE(sr_return_amt, 0)) AS total_return_amt,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(cs_ext_discount_amt) AS avg_discount
FROM sales_data
GROUP BY ROLLUP (sm_carrier, ca_county, ib_lower_bound, w_warehouse_name, cd_gender)
LIMIT 100
