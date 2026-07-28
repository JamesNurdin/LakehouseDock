WITH joined_data AS (
    SELECT
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        sm.sm_type,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p_cs.p_promo_name            AS promo_name,
        r.r_reason_desc,
        td.t_hour,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_customer_sk,
        cs.cs_bill_customer_sk,
        sr.sr_net_loss
    FROM catalog_sales cs
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd_cs
      ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN customer_address ca_cs
      ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p_cs
      ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN income_band ib
      ON hd_cs.hd_income_band_sk = ib.ib_income_band_sk
    /* store_sales joins */
    JOIN store_sales ss
      ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd_ss
      ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss
      ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN promotion p_ss
      ON ss.ss_promo_sk = p_ss.p_promo_sk
    /* store_returns joins */
    JOIN store_returns sr
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN household_demographics hd_sr
      ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr
      ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    WHERE w.w_state = 'CA'
      AND w.w_city = 'Oakland'
      AND sm.sm_type = 'AIR'
      AND p_cs.p_discount_active = 'Y'
      AND ib.ib_lower_bound >= 50000
      AND ib.ib_upper_bound <= 150000
      AND ca_ss.ca_state = 'TX'
      AND td.t_hour BETWEEN 9 AND 17
),
aggregated AS (
    SELECT
        w_warehouse_name,
        sm_type,
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        promo_name,
        r_reason_desc,
        t_hour,
        SUM(cs_ext_sales_price)      AS total_catalog_sales,
        SUM(ss_ext_sales_price)      AS total_store_sales,
        SUM(sr_net_loss)             AS total_return_loss,
        AVG(cs_ext_discount_amt)    AS avg_catalog_discount,
        COUNT(DISTINCT ss_customer_sk) AS unique_store_customers,
        COUNT(DISTINCT cs_bill_customer_sk) AS unique_catalog_customers
    FROM joined_data
    GROUP BY
        w_warehouse_name,
        sm_type,
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        promo_name,
        r_reason_desc,
        t_hour
)
SELECT
    w_warehouse_name,
    sm_type,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    promo_name,
    r_reason_desc,
    t_hour,
    total_catalog_sales,
    total_store_sales,
    total_return_loss,
    avg_catalog_discount,
    unique_store_customers,
    unique_catalog_customers,
    SUM(total_store_sales) OVER (
        PARTITION BY w_warehouse_name
        ORDER BY t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_store_sales_by_warehouse
FROM aggregated
ORDER BY total_store_sales DESC
LIMIT 100
