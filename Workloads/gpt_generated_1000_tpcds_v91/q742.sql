WITH ss_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity > 2
),
joined_data AS (
    SELECT
        s.s_state,
        s.s_store_id,
        promo_ss.p_promo_id,
        wp.wp_type,
        ss.ss_quantity,
        ws.ws_quantity,
        ss.ss_net_paid,
        ss.ss_ticket_number
    FROM ss_sample ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion promo_ss
        ON ss.ss_promo_sk = promo_ss.p_promo_sk
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site webs
        ON ws.ws_web_site_sk = webs.web_site_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN promotion promo_ws
        ON ws.ws_promo_sk = promo_ws.p_promo_sk
    WHERE
        s.s_state = 'CA'
        AND c.c_birth_country = 'United States'
        AND promo_ss.p_discount_active = 'Y'
        AND wp.wp_type = 'order'
        AND w.w_state = 'WA'
        AND i.inv_quantity_on_hand > 100
),
aggregated AS (
    SELECT
        s_state,
        s_store_id,
        p_promo_id,
        wp_type,
        SUM(ss_quantity) AS total_store_qty,
        SUM(ws_quantity) AS total_web_qty,
        SUM(ss_net_paid) AS total_net_paid,
        AVG(ss_quantity) AS avg_store_qty,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
        MIN(ss_net_paid) AS min_net_paid,
        MAX(ss_net_paid) AS max_net_paid
    FROM joined_data
    GROUP BY ROLLUP (s_state, s_store_id, p_promo_id, wp_type)
    HAVING SUM(ss_net_paid) > 1000
)
SELECT
    s_state,
    s_store_id,
    p_promo_id,
    wp_type,
    total_store_qty,
    total_web_qty,
    total_net_paid,
    avg_store_qty,
    distinct_tickets,
    min_net_paid,
    max_net_paid,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_paid DESC) AS rn_store
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
