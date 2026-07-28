WITH base AS (
    SELECT
        ca_bill.ca_state AS state,
        p_cs.p_promo_name AS promotion,
        cs.cs_net_paid + ss.ss_net_paid AS total_net_paid,
        cs.cs_net_profit + ss.ss_net_profit AS total_net_profit,
        p_cs.p_cost AS promo_cost
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_page wp ON wp.wp_customer_sk = c_bill.c_customer_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
),
agg AS (
    SELECT
        state,
        promotion,
        SUM(total_net_paid) AS total_net_paid,
        SUM(total_net_profit) AS total_net_profit,
        CASE WHEN SUM(total_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        AVG(promo_cost) AS avg_promo_cost
    FROM base
    GROUP BY ROLLUP (state, promotion)
)
SELECT
    state,
    promotion,
    total_net_paid,
    total_net_profit,
    profit_category,
    avg_promo_cost,
    (SELECT AVG(p_sub.p_cost) FROM promotion p_sub) AS overall_avg_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_net_paid DESC) AS state_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
