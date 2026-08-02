WITH combined_sales AS (
    SELECT 
        s.s_store_id AS store_id,
        p.p_promo_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_cnt,
        CASE 
            WHEN p.p_discount_active = 'Y' THEN SUM(ss.ss_net_profit) * 0.9
            ELSE SUM(ss.ss_net_profit)
        END AS adjusted_profit,
        p.p_discount_active
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_state = 'TX'
      AND s.s_rec_start_date >= DATE '2020-01-01'
    GROUP BY s.s_store_id, p.p_promo_id, p.p_discount_active
    HAVING SUM(ss.ss_net_profit) > 0

    UNION

    SELECT 
        'WEB' AS store_id,
        p.p_promo_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS txn_cnt,
        CASE 
            WHEN p.p_discount_active = 'Y' THEN SUM(ws.ws_net_profit) * 0.9
            ELSE SUM(ws.ws_net_profit)
        END AS adjusted_profit,
        p.p_discount_active
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_event = 'N'
    GROUP BY p.p_promo_id, p.p_discount_active
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT 
    cs.store_id,
    cs.p_promo_id,
    cs.total_sales,
    cs.total_profit,
    cs.adjusted_profit,
    cs.txn_cnt,
    ROW_NUMBER() OVER (PARTITION BY cs.p_promo_id ORDER BY cs.total_sales DESC) AS sales_rank,
    (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_promo_id = cs.p_promo_id
    ) AS max_promo_cost,
    CASE 
        WHEN cs.total_sales > (
            SELECT AVG(cs2.total_sales)
            FROM combined_sales cs2
            WHERE cs2.p_promo_id = cs.p_promo_id
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category
FROM combined_sales cs
WHERE cs.total_sales > (
    SELECT AVG(total_sales)
    FROM combined_sales
)
ORDER BY cs.total_sales DESC, cs.store_id ASC
