WITH filtered_customers AS (
    SELECT c_customer_sk
    FROM customer
    WHERE c_birth_country IN ('JAPAN', 'SWITZERLAND')
      AND c_preferred_cust_flag = 'Y'
)
SELECT DISTINCT
       source,
       sales_hour,
       dept,
       channel,
       total_sales,
       avg_discount,
       order_count
FROM (
    -- Catalog sales side
    SELECT
        'Catalog' AS source,
        t.t_hour AS sales_hour,
        cp.cp_department AS dept,
        p.p_channel_tv AS channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM catalog_sales cs
    JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE EXISTS (
            SELECT 1 FROM filtered_customers fc WHERE fc.c_customer_sk = cs.cs_bill_customer_sk
          )
      AND p.p_channel_tv = 'Y'
      AND sm.sm_type = 'AIR'
      AND cs.cs_quantity > 1
      AND cs.cs_sales_price > 100.00
      AND cp.cp_type = 'PROMO'
      AND EXISTS (
            SELECT 1 FROM income_band ib
            WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
              AND ib.ib_lower_bound >= 50000
          )
    GROUP BY t.t_hour, cp.cp_department, p.p_channel_tv

    UNION ALL

    -- Web sales side
    SELECT
        'Web' AS source,
        t.t_hour AS sales_hour,
        NULL AS dept,
        p.p_channel_tv AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN time_dim t               ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p              ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm             ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE EXISTS (
            SELECT 1 FROM filtered_customers fc WHERE fc.c_customer_sk = ws.ws_bill_customer_sk
          )
      AND p.p_channel_tv = 'Y'
      AND sm.sm_type = 'AIR'
      AND ws.ws_quantity > 1
      AND ws.ws_sales_price > 100.00
      AND EXISTS (
            SELECT 1 FROM income_band ib
            WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
              AND ib.ib_lower_bound >= 50000
          )
    GROUP BY t.t_hour, p.p_channel_tv
) AS agg_results
ORDER BY total_sales DESC
LIMIT 100
