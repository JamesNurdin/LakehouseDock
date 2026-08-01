WITH store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price
    FROM store_sales ss
    LEFT JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
    WHERE ss.ss_quantity > 0
)
SELECT
    s.s_store_name,
    cp.cp_department,
    SUM(ss_agg.ss_net_profit) AS total_store_net_profit,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    AVG(ss_agg.ss_ext_discount_amt) AS avg_store_discount,
    (
        SELECT SUM(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_warehouse_sk = w_cs.w_warehouse_sk
    ) AS total_inventory_in_warehouse,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(wr.wr_net_loss) AS total_web_returns_loss,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit
FROM store_sales_agg ss_agg
JOIN store s
    ON ss_agg.ss_store_sk = s.s_store_sk
JOIN customer c
    ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd_ss
    ON ss_agg.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss
    ON ss_agg.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss_agg.ss_ticket_number
   AND sr.sr_item_sk = ss_agg.ss_item_sk
   AND sr.sr_store_sk = s.s_store_sk
LEFT JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN warehouse w_cs
    ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN inventory inv
    ON inv.inv_warehouse_sk = w_cs.w_warehouse_sk
JOIN household_demographics hd_cs
    ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
JOIN customer_address ca_cs
    ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
JOIN income_band ib
    ON hd_cs.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE
    s.s_state = 'CA'
    AND cp.cp_department = 'Electronics'
    AND p_cs.p_discount_active = 'Y'
    AND ib.ib_upper_bound <= 120000
    AND inv.inv_quantity_on_hand > 1000
GROUP BY
    s.s_store_name,
    cp.cp_department,
    w_cs.w_warehouse_sk
HAVING
    SUM(ss_agg.ss_net_profit) > 100000
ORDER BY
    total_store_net_profit DESC
