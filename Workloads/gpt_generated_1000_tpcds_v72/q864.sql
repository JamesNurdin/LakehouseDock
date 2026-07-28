WITH base AS (
    SELECT
        w.w_warehouse_name,
        sm1.sm_type,
        promo1.p_promo_name,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS total_positive_profit,
        SUM(promo_extra.p_cost) AS total_extra_promo_cost
    FROM catalog_sales cs
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN ship_mode sm1
        ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion promo1
        ON cs.cs_promo_sk = promo1.p_promo_sk
    -- second reference to promotion for a different analytical purpose
    JOIN promotion promo_extra
        ON cs.cs_promo_sk = promo_extra.p_promo_sk
    -- join the web sales side using the same billing customer
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
    JOIN ship_mode sm2
        ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN warehouse w2
        ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN promotion promo2
        ON ws.ws_promo_sk = promo2.p_promo_sk
    WHERE EXISTS (
        SELECT 1 FROM promotion p3
        WHERE p3.p_promo_sk = cs.cs_promo_sk
          AND p3.p_discount_active = 'Y'
    )
    GROUP BY w.w_warehouse_name, sm1.sm_type, promo1.p_promo_name
)
SELECT
    b.w_warehouse_name,
    b.sm_type,
    b.p_promo_name,
    b.total_catalog_net_paid,
    b.total_web_net_paid,
    b.total_positive_profit,
    b.total_extra_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY b.w_warehouse_name ORDER BY b.total_catalog_net_paid DESC) AS warehouse_rank
FROM base b
ORDER BY b.total_catalog_net_paid DESC
LIMIT 100
