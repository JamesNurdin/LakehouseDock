WITH sales_agg AS (
    SELECT
        w.w_state,
        c.c_birth_country,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid_inc_ship_tax) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
        SUM(ws.ws_net_paid_inc_ship_tax) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    -- Join web_sales and its dimensions
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    -- Join inventory
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        c.c_birth_country = 'JORDAN'
        AND ca.ca_gmt_offset = -5.00
        AND w.w_state = 'CA'
        AND d.d_year = 2001
        AND cs.cs_quantity BETWEEN 1 AND 10
        AND cs.cs_net_paid_inc_ship_tax > 1000
        AND p_cs.p_discount_active = 'Y'
        AND p_ws.p_discount_active = 'Y'
    GROUP BY ROLLUP (w.w_state, c.c_birth_country, d.d_year, d.d_month_seq)
)
SELECT
    w_state,
    c_birth_country,
    d_year,
    d_month_seq,
    catalog_net_paid,
    catalog_net_profit,
    web_net_paid,
    web_net_profit,
    catalog_order_cnt,
    web_order_cnt,
    total_inventory_on_hand,
    CASE WHEN (catalog_net_profit + web_net_profit) > 50000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_flag,
    (
        SELECT
            COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ws.ws_net_profit), 0)
        FROM catalog_sales cs
        JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
        WHERE d1.d_year = 2001
    ) AS year_2001_total_profit,
    SUM(catalog_net_profit + web_net_profit) OVER (
        PARTITION BY w_state
        ORDER BY d_year, d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS state_running_profit
FROM sales_agg
ORDER BY
    w_state,
    c_birth_country,
    d_year,
    d_month_seq
LIMIT 100
