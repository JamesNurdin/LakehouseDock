WITH base AS (
    SELECT
        cc.cc_name,
        cc.cc_employees,
        cs.cs_ext_ship_cost,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        sr.sr_return_amt,
        sr.sr_net_loss,
        r.r_reason_desc
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cc.cc_employees > 1000000
      AND cs.cs_ext_ship_cost > 1000
      AND sr.sr_return_amt > 500
      AND hd.hd_income_band_sk = 11
)
SELECT
    cc_name,
    r_reason_desc,
    hd_buy_potential,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_returns,
    SUM(cs_net_profit) - SUM(sr_net_loss) AS net_profit,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(cs_ext_ship_cost) AS avg_ship_cost
FROM base
GROUP BY cc_name, r_reason_desc, hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
