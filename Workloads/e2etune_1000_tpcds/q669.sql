WITH catalog_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        cp.cp_type,
        td.t_shift,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_qty,
        AVG(cs.cs_sales_price) AS avg_catalog_price
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_type = 'monthly'
      AND p.p_discount_active = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
      AND hd.hd_vehicle_count >= 2
    GROUP BY p.p_promo_sk, p.p_promo_name, cp.cp_type, td.t_shift
),
store_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        td.t_shift,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_qty,
        AVG(ss.ss_sales_price) AS avg_store_price
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_discount_active = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
      AND hd.hd_vehicle_count >= 2
    GROUP BY p.p_promo_sk, p.p_promo_name, td.t_shift
)
SELECT
    co.p_promo_sk,
    co.p_promo_name,
    co.cp_type,
    co.t_shift,
    co.catalog_net_profit,
    st.store_net_profit,
    co.catalog_net_profit - st.store_net_profit AS profit_diff,
    CASE WHEN st.store_net_profit = 0 THEN NULL
         ELSE co.catalog_net_profit / st.store_net_profit END AS profit_ratio,
    ROW_NUMBER() OVER (PARTITION BY co.cp_type ORDER BY (co.catalog_net_profit - st.store_net_profit) DESC) AS profit_diff_rank
FROM catalog_agg co
LEFT JOIN store_agg st
    ON co.p_promo_sk = st.p_promo_sk
   AND co.t_shift = st.t_shift
ORDER BY profit_diff DESC
LIMIT 50
