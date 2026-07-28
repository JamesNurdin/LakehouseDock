/* Goal: Compare total profit and order count for two distinct carrier/state combinations across different years, aggregated by year and ship type */
WITH sales_union AS (
    SELECT
        d_sold.d_year AS year,
        sm.sm_type AS ship_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sm.sm_carrier = 'MSC'
      AND cc.cc_state = 'CA'
      AND ib.ib_upper_bound > 50000
      AND d_sold.d_year = 2001
    GROUP BY d_sold.d_year, sm.sm_type, ib.ib_lower_bound, ib.ib_upper_bound

    UNION ALL

    SELECT
        d_sold.d_year AS year,
        sm.sm_type AS ship_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sm.sm_carrier = 'USPS'
      AND cc.cc_state = 'TX'
      AND ib.ib_upper_bound > 50000
      AND d_sold.d_year = 2002
    GROUP BY d_sold.d_year, sm.sm_type, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    year,
    ship_type,
    SUM(net_profit) AS total_profit,
    SUM(order_cnt) AS total_orders
FROM sales_union
GROUP BY year, ship_type
ORDER BY total_profit DESC
