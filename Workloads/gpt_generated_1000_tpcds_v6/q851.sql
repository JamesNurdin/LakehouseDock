WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_promo_sk,
        SUM(ss_net_profit) AS store_sales_profit,
        AVG(ss_ext_discount_amt) AS avg_store_discount,
        COUNT(*) AS store_sales_cnt
    FROM store_sales
    WHERE ss_coupon_amt > 500
      AND ss_list_price BETWEEN 20 AND 120
    GROUP BY ss_store_sk, ss_promo_sk
)
SELECT
    s.s_state,
    s.s_division_id,
    p.p_promo_name,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(cs.cs_net_profit) + ss_agg.store_sales_profit + SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(CASE WHEN cs.cs_ext_discount_amt > 200 THEN cs.cs_ext_discount_amt END) AS avg_large_discount,
    SUM(CASE WHEN ws.ws_quantity >= 2 THEN ws.ws_net_paid ELSE 0 END) AS web_sales_paid_qty_ge2
FROM ss_agg
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
    AND c.c_customer_sk = ws.ws_bill_customer_sk
WHERE s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND c.c_birth_year = 1985
  AND cs.cs_ext_sales_price > 1000
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_promo_sk = p.p_promo_sk
          AND ws2.ws_net_profit > 500
        LIMIT 1
    )
GROUP BY s.s_state, s.s_division_id, p.p_promo_name, ss_agg.store_sales_profit
ORDER BY total_net_profit DESC
LIMIT 100
