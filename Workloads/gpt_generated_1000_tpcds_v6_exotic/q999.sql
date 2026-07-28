WITH base AS (
    SELECT
        s.s_store_name,
        s.s_state,
        p.p_promo_id,
        p.p_discount_active,
        d_ss.d_year,
        ca_ss.ca_state,
        ss.ss_net_profit,
        cs.cs_net_profit,
        ws.ws_net_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d_ss.d_date_sk
        AND cs.cs_sold_time_sk = t_ss.t_time_sk
        AND cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d_ss.d_date_sk
        AND cr.cr_returned_time_sk = t_ss.t_time_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_ss.d_date_sk
        AND ws.ws_sold_time_sk = t_ss.t_time_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d_ss.d_date_sk
        AND wr.wr_returned_time_sk = t_ss.t_time_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE d_ss.d_year = 2001
      AND ca_ss.ca_state IN ('CA', 'TX', 'NY')
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cs.cs_order_number
            AND cr2.cr_return_quantity > 0
      )
),
aggregated AS (
    SELECT
        s_store_name,
        p_promo_id,
        d_year,
        SUM(ss_net_profit) AS store_net_profit,
        SUM(cs_net_profit) AS catalog_net_profit,
        SUM(ws_net_profit) AS web_net_profit,
        SUM(ss_net_profit + cs_net_profit + ws_net_profit) AS total_profit,
        CASE
            WHEN SUM(ss_net_profit + cs_net_profit + ws_net_profit) > 500000 THEN 'HIGH'
            ELSE 'LOW'
        END AS profit_level
    FROM (
        SELECT
            s_store_name,
            p_promo_id,
            d_year,
            ss_net_profit,
            cs_net_profit,
            ws_net_profit
        FROM base
    ) agg
    GROUP BY s_store_name, p_promo_id, d_year
)
SELECT
    s_store_name,
    p_promo_id,
    d_year,
    store_net_profit,
    catalog_net_profit,
    web_net_profit,
    total_profit,
    profit_level,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER (PARTITION BY d_year ORDER BY total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    (SELECT COUNT(*) FROM promotion WHERE p_discount_active = 'Y') AS active_promo_cnt
FROM aggregated
ORDER BY profit_rank
LIMIT 100
