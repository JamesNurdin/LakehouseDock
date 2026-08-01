WITH combined_sales AS (
    SELECT
        p.p_promo_id AS promo_id,
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
        FROM income_band ib
        WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
    ) ib
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
      AND t.t_hour = 13
      AND p.p_discount_active = 'Y'
      AND ib.ib_lower_bound >= 60000
      AND hd.hd_vehicle_count >= 2
      AND sm.sm_type = 'AIR'
      AND cs.cs_quantity > 5
    GROUP BY p.p_promo_id, ib.ib_lower_bound, ib.ib_upper_bound

    UNION

    SELECT
        p.p_promo_id AS promo_id,
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer cust ON ss.ss_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
        FROM income_band ib
        WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
    ) ib
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2000
      AND t.t_hour = 13
      AND p.p_discount_active = 'Y'
      AND ib.ib_lower_bound >= 60000
      AND hd.hd_vehicle_count >= 2
      AND ss.ss_quantity > 5
    GROUP BY p.p_promo_id, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    promo_id,
    lower_bound,
    upper_bound,
    SUM(total_net_profit) AS grand_total_net_profit,
    SUM(total_quantity) AS grand_total_quantity,
    AVG(avg_discount) AS overall_avg_discount
FROM combined_sales
GROUP BY promo_id, lower_bound, upper_bound
ORDER BY grand_total_net_profit DESC
LIMIT 100
