WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        ss.ss_net_paid,
        s.s_store_id,
        s.s_division_name,
        s.s_division_id,
        s.s_state,
        w.w_state,
        t1.t_hour,
        p_cs.p_channel_details,
        cd1.cd_gender
    FROM catalog_sales cs
    JOIN time_dim t1
        ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN customer_demographics cd1
        ON cs.cs_bill_cdemo_sk = cd1.cd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    -- additional required joins to satisfy the join‑rule set
    JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN customer_demographics cd2
        ON ss.ss_cdemo_sk = cd2.cd_demo_sk
    WHERE s.s_division_id = 1
      AND s.s_state = 'CA'
      AND w.w_state = 'CA'
      AND t1.t_hour BETWEEN 9 AND 17
      AND p_cs.p_channel_details LIKE '%Offences%'
      AND cd1.cd_gender = 'M'
      AND cs.cs_quantity > 5
)
SELECT
    s_store_id,
    s_division_name,
    CASE WHEN SUM(cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    SUM(ss_net_paid) AS total_store_net_paid,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    AVG(cs_ext_discount_amt) AS avg_catalog_discount,
    MIN(cs_net_paid) AS min_catalog_net_paid,
    MAX(cs_net_paid) AS max_catalog_net_paid
FROM joined
GROUP BY s_store_id, s_division_name
ORDER BY total_catalog_net_paid DESC
LIMIT 100
