WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000
      AND cs.cs_ext_discount_amt BETWEEN 500 AND 4000
      AND cs.cs_quantity >= 1
      AND cs.cs_net_profit > 0
      AND cs.cs_ship_mode_sk IS NOT NULL
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2455000
),
promo_except AS (
    SELECT p.p_promo_sk
    FROM promotion p
    EXCEPT
    SELECT cs.cs_promo_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_discount_amt > 3000
),
full_demo AS (
    SELECT hd.hd_demo_sk,
           hd.hd_income_band_sk,
           hd.hd_buy_potential,
           hd.hd_dep_count,
           hd.hd_vehicle_count
    FROM household_demographics hd
    FULL OUTER JOIN (
        SELECT DISTINCT cs_bill_hdemo_sk AS hd_demo_sk
        FROM catalog_sales
    ) cd
        ON hd.hd_demo_sk = cd.hd_demo_sk
),
aggregated AS (
    SELECT
        cc.cc_call_center_id        AS call_center_id,
        p.p_promo_id                AS promo_id,
        w.w_warehouse_name          AS warehouse_name,
        t.t_hour                    AS hour,
        SUM(fs.cs_ext_sales_price)  AS total_sales,
        SUM(fs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT fs.cs_order_number) AS orders,
        AVG(fs.cs_net_profit)       AS avg_profit
    FROM filtered_sales fs
    JOIN promotion p
        ON fs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON fs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON fs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc
        ON fs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN full_demo fd
        ON fs.cs_bill_hdemo_sk = fd.hd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM call_center cc2
        WHERE cc2.cc_call_center_sk = fs.cs_call_center_sk
          AND cc2.cc_manager = 'Ryan Burchett'
    )
      AND NOT EXISTS (
        SELECT 1
        FROM promo_except pe
        WHERE pe.p_promo_sk = fs.cs_promo_sk
      )
      AND w.w_zip LIKE '3____'
      AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
      AND t.t_meal_time = 'Dinner'
      AND p.p_channel_email = 'Y'
    GROUP BY
        cc.cc_call_center_id,
        p.p_promo_id,
        w.w_warehouse_name,
        t.t_hour
),
final AS (
    SELECT
        call_center_id,
        promo_id,
        warehouse_name,
        hour,
        total_sales,
        total_discount,
        orders,
        avg_profit,
        total_sales / NULLIF(total_discount, 0) AS sales_per_discount
    FROM aggregated
    WHERE total_sales > 5000
)
SELECT
    call_center_id,
    promo_id,
    warehouse_name,
    hour,
    total_sales,
    total_discount,
    orders,
    avg_profit,
    sales_per_discount
FROM final
ORDER BY total_sales DESC
LIMIT 100
