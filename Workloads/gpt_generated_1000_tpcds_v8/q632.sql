WITH base AS (
    SELECT
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        sr.sr_net_loss   AS sr_net_loss,
        cr.cr_net_loss   AS cr_net_loss,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state      AS ca_state,
        i.i_brand_id,
        p.p_discount_active,
        s.s_state,
        cc.cc_class,
        t1.t_hour        AS ss_hour,
        cp.cp_catalog_page_sk,
        r.r_reason_desc,
        wp.wp_web_page_sk,
        wsite.web_site_sk
    FROM store_sales ss
    JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t2 ON cs.cs_sold_time_sk = t2.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN time_dim t3 ON cr.cr_returned_time_sk = t3.t_time_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t4 ON ws.ws_sold_time_sk = t4.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    WHERE
        s.s_state = 'CA'
        AND cc.cc_class = 'CLASS1'
        AND t1.t_hour BETWEEN 9 AND 17
        AND i.i_brand_id = 100
        AND p.p_discount_active = 'Y'
        AND EXISTS (
            SELECT 1 FROM catalog_sales cs_sub
            WHERE cs_sub.cs_bill_customer_sk = c.c_customer_sk
              AND cs_sub.cs_net_profit > 5000
        )
)
SELECT *
FROM (
    SELECT
        b.c_customer_sk,
        b.s_state,
        SUM(b.ss_net_profit) + SUM(b.cs_net_profit) + SUM(b.ws_net_profit) AS total_amount,
        CASE WHEN SUM(b.ss_net_profit) + SUM(b.cs_net_profit) + SUM(b.ws_net_profit) > 10000 THEN 'High' ELSE 'Normal' END AS category,
        ROW_NUMBER() OVER (PARTITION BY b.s_state ORDER BY SUM(b.ss_net_profit) + SUM(b.cs_net_profit) + SUM(b.ws_net_profit) DESC) AS state_rank,
        (SELECT COUNT(*) FROM catalog_sales cs_sub WHERE cs_sub.cs_bill_customer_sk = b.c_customer_sk AND cs_sub.cs_net_profit > 5000) AS txn_cnt
    FROM base b
    GROUP BY CUBE (b.c_customer_sk, b.s_state)

    UNION DISTINCT

    SELECT
        b.c_customer_sk,
        b.s_state,
        -(SUM(b.sr_net_loss) + SUM(b.cr_net_loss)) AS total_amount,
        CASE WHEN -(SUM(b.sr_net_loss) + SUM(b.cr_net_loss)) < -5000 THEN 'HighLoss' ELSE 'Moderate' END AS category,
        ROW_NUMBER() OVER (PARTITION BY b.s_state ORDER BY -(SUM(b.sr_net_loss) + SUM(b.cr_net_loss)) ASC) AS state_rank,
        (SELECT COUNT(*) FROM store_returns sr_sub WHERE sr_sub.sr_customer_sk = b.c_customer_sk AND sr_sub.sr_net_loss > 2000) AS txn_cnt
    FROM base b
    GROUP BY CUBE (b.c_customer_sk, b.s_state)
) AS combined
ORDER BY total_amount DESC
OFFSET 0
LIMIT 100
