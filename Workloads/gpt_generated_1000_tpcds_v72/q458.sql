WITH sales_base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cc.cc_state,
        p.p_promo_name,
        sm.sm_type,
        w.w_warehouse_name,
        s.s_store_name,
        cp.cp_department,
        cs.cs_net_profit AS cs_profit,
        ws.ws_net_profit AS ws_profit,
        wr.wr_net_loss   AS wr_loss,
        CASE
            WHEN cs.cs_net_profit + ws.ws_net_profit - wr.wr_net_loss > 0 THEN 'POSITIVE'
            ELSE 'NEGATIVE'
        END AS profit_indicator,
        (cs.cs_net_profit + ws.ws_net_profit - wr.wr_net_loss) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
       AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_bill_customer_sk = c.c_customer_sk
       AND ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND c.c_birth_month = 7
      AND cc.cc_state = 'TX'
      AND p.p_discount_active = 'Y'
),
customer_agg AS (
    SELECT
        d_year,
        c_customer_id AS entity_id,
        'CUSTOMER' AS entity_type,
        SUM(total_profit) AS profit,
        COUNT(*) AS trans_cnt
    FROM sales_base
    GROUP BY GROUPING SETS ((d_year, c_customer_id), (d_year), ())
),
store_agg AS (
    SELECT
        d_year,
        s_store_name AS entity_id,
        'STORE' AS entity_type,
        SUM(total_profit) AS profit,
        COUNT(*) AS trans_cnt
    FROM sales_base
    GROUP BY GROUPING SETS ((d_year, s_store_name), (d_year), ())
)
SELECT
    d_year,
    entity_id,
    entity_type,
    profit,
    trans_cnt,
    ROW_NUMBER() OVER (PARTITION BY entity_type ORDER BY profit DESC) AS rank_in_type
FROM (
    SELECT * FROM customer_agg
    UNION ALL
    SELECT * FROM store_agg
) u
ORDER BY d_year, entity_type, rank_in_type
LIMIT 100
