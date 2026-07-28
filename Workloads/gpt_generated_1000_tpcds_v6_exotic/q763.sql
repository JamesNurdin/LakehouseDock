WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_ext_sales_price)                         AS store_sales_total,
        SUM(cs.cs_ext_sales_price)                         AS catalog_sales_total,
        SUM(sr.sr_return_amt)                              AS store_returns_total,
        SUM(wr.wr_return_amt)                              AS web_returns_total,
        SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) AS net_profit,
        (SELECT AVG(p2.p_cost) FROM promotion p2)          AS avg_all_promo_cost
    FROM store_sales ss
        JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN catalog_sales cs ON cs.cs_sold_time_sk = t_ss.t_time_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE
        i.i_current_price > 100
        AND s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND sm.sm_carrier = 'LATVIAN'
        AND r.r_reason_desc = 'Damaged'
        AND ca.ca_country = 'United States'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state
    HAVING
        (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss))) > 1000
)
SELECT
    b.s_store_id,
    b.s_store_name,
    b.s_state,
    b.store_sales_total,
    b.catalog_sales_total,
    b.store_returns_total,
    b.web_returns_total,
    b.net_profit,
    b.avg_all_promo_cost,
    RANK() OVER (ORDER BY b.net_profit DESC) AS profit_rank,
    CASE
        WHEN b.net_profit >= 5000 THEN 'High'
        WHEN b.net_profit >= 2000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM base b
ORDER BY profit_rank
LIMIT 100
