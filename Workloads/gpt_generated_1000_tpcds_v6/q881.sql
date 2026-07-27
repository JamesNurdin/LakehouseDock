WITH combined AS (
    SELECT
        s1.s_manager AS store_manager,
        p1.p_promo_name AS promo_name,
        sm.sm_carrier AS carrier,
        r.r_reason_desc AS return_reason,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales_inc_tax,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(cr.cr_net_loss) AS total_return_net_loss,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_sales_customers,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
    FROM store_sales ss
    JOIN store s1 ON ss.ss_store_sk = s1.s_store_sk
    JOIN store s2 ON ss.ss_store_sk = s2.s_store_sk                     -- second alias of store
    JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
    JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk                 -- second alias of promotion
    JOIN customer_demographics cd_sales ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
    JOIN catalog_returns cr ON 1 = 1                                      -- cross‑join to bring returns into the same query
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    WHERE p1.p_discount_active = 'Y'
      AND sm.sm_contract IS NOT NULL
    GROUP BY
        s1.s_manager,
        p1.p_promo_name,
        sm.sm_carrier,
        r.r_reason_desc
    HAVING SUM(ss.ss_net_paid_inc_tax) > 1000
)
SELECT DISTINCT
    store_manager,
    promo_name,
    carrier,
    return_reason,
    total_sales_inc_tax,
    total_sales_profit,
    total_return_net_loss,
    distinct_sales_customers,
    distinct_return_orders,
    ROW_NUMBER() OVER (PARTITION BY store_manager ORDER BY total_sales_inc_tax DESC) AS sales_rank
FROM combined
ORDER BY total_sales_inc_tax DESC
LIMIT 100
