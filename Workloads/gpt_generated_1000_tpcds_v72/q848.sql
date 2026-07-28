WITH sales_base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_net_profit,
        d.d_year,
        i.i_category,
        i.i_brand,
        s.s_store_name,
        s.s_state,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        dm.cd_gender,
        p.p_promo_name,
        p.p_discount_active,
        cp.cp_type,
        cp.cp_description,
        cr.cr_return_quantity,
        sr.sr_return_quantity,
        wr.wr_return_quantity,
        r.r_reason_desc,
        sm.sm_type,
        inv.inv_quantity_on_hand,
        cc.cc_manager,
        ws.web_name,
        wp.wp_url
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics dm ON ss.ss_cdemo_sk = dm.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_sales cs ON cs.cs_order_number = ss.ss_ticket_number AND cs.cs_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND i.i_category = 'Sports'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cp.cp_type = 'Standard'
      AND ws.web_name LIKE '%Online%'
),
agg_sales AS (
    SELECT
        s_store_name,
        s_state,
        d_year,
        cc_manager,
        cp_description,
        web_name,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT sr_return_quantity) AS store_return_cnt,
        COUNT(DISTINCT cr_return_quantity) AS catalog_return_cnt,
        COUNT(DISTINCT wr_return_quantity) AS web_return_cnt
    FROM sales_base
    GROUP BY
        s_store_name,
        s_state,
        d_year,
        cc_manager,
        cp_description,
        web_name
)
SELECT
    s_store_name,
    s_state,
    d_year,
    total_net_profit,
    cc_manager,
    cp_description,
    web_name,
    store_return_cnt,
    catalog_return_cnt,
    web_return_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY profit_rank
LIMIT 100
