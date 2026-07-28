WITH sales_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        i.i_category,
        p.p_promo_name,
        c.c_email_address
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z]+\\.[A-Za-z]+@.*\\.org$')
      AND p.p_promo_name LIKE '%Discount%'
),
agg AS (
    SELECT
        i_category,
        p_promo_name,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        SUM(cs_net_profit) AS total_profit,
        AVG(cs_quantity) AS avg_qty,
        CONCAT('Promo-', regexp_extract(p_promo_name, '([A-Z]+)', 1)) AS promo_code
    FROM sales_filtered
    GROUP BY i_category, p_promo_name
)
SELECT
    i_category,
    p_promo_name,
    orders_cnt,
    total_profit,
    avg_qty,
    promo_code,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
