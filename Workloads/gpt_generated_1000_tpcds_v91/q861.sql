WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        s.s_store_name,
        d_sales.d_year,
        d_sales.d_month_seq,
        ca.ca_state,
        cd.cd_gender,
        p1.p_promo_name,
        p1.p_discount_active,
        i.inv_quantity_on_hand,
        w_inv.w_warehouse_name,
        sm.sm_type,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        wp.wp_url,
        cp.cp_catalog_number,
        cc.cc_name,
        r.r_reason_desc,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        d_ret.d_date AS return_date,
        t_ret.t_time AS return_time,
        w_ws.w_warehouse_name AS ws_warehouse_name,
        p2.p_promo_name AS ws_promo_name
    FROM store_sales ss
    INNER JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    INNER JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
    LEFT JOIN inventory i ON i.inv_date_sk = d_sales.d_date_sk
    LEFT JOIN warehouse w_inv ON i.inv_warehouse_sk = w_inv.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                              AND sr.sr_item_sk = ss.ss_item_sk
                              AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d_sales.d_date_sk
                           AND ws.ws_sold_time_sk = t_sales.t_time_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
    LEFT JOIN call_center cc ON cc.cc_open_date_sk = d_sales.d_date_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
    )
      AND EXISTS (
        SELECT 1
        FROM promotion p_check
        WHERE p_check.p_promo_sk = ss.ss_promo_sk
          AND p_check.p_discount_active = 'Y'
      )
),
agg AS (
    SELECT
        s_store_name,
        d_year,
        d_month_seq,
        ca_state,
        cd_gender,
        p_promo_name,
        SUM(ss_ext_sales_price) AS total_sales_amount,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
        SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_inventory_on_hand,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM base
    GROUP BY
        s_store_name,
        d_year,
        d_month_seq,
        ca_state,
        cd_gender,
        p_promo_name
)
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    ca_state,
    cd_gender,
    p_promo_name,
    total_sales_amount,
    total_profit,
    distinct_customers,
    total_inventory_on_hand,
    total_transactions,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_sales_amount DESC) AS sales_rank_per_store
FROM agg
ORDER BY total_sales_amount DESC, s_store_name
