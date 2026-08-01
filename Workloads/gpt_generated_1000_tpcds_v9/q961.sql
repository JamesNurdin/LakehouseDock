WITH joined_data AS (
    SELECT
        s.s_store_id,
        s.s_state,
        i.i_item_id,
        i.i_category,
        i.i_item_desc,
        t.t_hour,
        ca.ca_suite_number,
        ca.ca_city,
        ss.ss_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss,
        cs.cs_ext_tax,
        sr.sr_store_credit,
        r.r_reason_desc,
        /* scalar subquery for catalog sales count */
        (SELECT COUNT(*) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = i.i_item_sk) AS catalog_sales_cnt,
        /* lateral subquery for latest promotion for the item */
        latest_promo.p_promo_name,
        latest_promo.p_discount_active
    FROM store s
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    CROSS JOIN LATERAL (
        SELECT p2.p_promo_name, p2.p_discount_active
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
        ORDER BY p2.p_start_date_sk DESC
        LIMIT 1
    ) AS latest_promo
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r_wr
        ON r_wr.r_reason_sk = wr.wr_reason_sk
    WHERE
        i.i_category = 'Electronics'
        AND s.s_state = 'CA'
        AND ca.ca_suite_number = 'Suite 100'
        AND t.t_hour BETWEEN 8 AND 20
        AND cs.cs_ext_tax > 50
        AND sr.sr_store_credit > 500
        AND latest_promo.p_discount_active = 'Y'
        AND EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_item_sk = i.i_item_sk
                AND wr2.wr_net_loss > 100
        )
)
SELECT
    s_store_id,
    s_state,
    i_item_id,
    i_category,
    total_net_profit,
    total_net_loss,
    net_total,
    profit_classification,
    catalog_sales_cnt,
    p_promo_name,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY net_total DESC) AS item_rank
FROM (
    SELECT
        s_store_id,
        s_state,
        i_item_id,
        i_category,
        SUM(COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0)) AS total_net_profit,
        SUM(COALESCE(sr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_net_loss,
        SUM(COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0) - COALESCE(sr_net_loss, 0) - COALESCE(wr_net_loss, 0)) AS net_total,
        CASE
            WHEN SUM(COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0) - COALESCE(sr_net_loss, 0) - COALESCE(wr_net_loss, 0)) > 5000 THEN 'High'
            WHEN SUM(COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0) - COALESCE(sr_net_loss, 0) - COALESCE(wr_net_loss, 0)) > 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_classification,
        MAX(catalog_sales_cnt) AS catalog_sales_cnt,
        MAX(p_promo_name) AS p_promo_name
    FROM joined_data
    GROUP BY s_store_id, s_state, i_item_id, i_category
    HAVING SUM(COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0)) > 1000
) AS agg
ORDER BY net_total DESC
LIMIT 100
