WITH agg_sales AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ss.ss_quantity) AS store_sales_quantity,
        SUM(sr.sr_net_loss) AS store_returns_net_loss,
        SUM(ws.ws_net_paid) AS web_sales_net_paid,
        SUM(ws.ws_quantity) AS web_sales_quantity,
        SUM(wr.wr_net_loss) AS web_returns_net_loss,
        SUM(inv.inv_quantity_on_hand) AS inventory_on_hand,
        SUM(p.p_cost) AS total_promo_cost,
        SUM(CASE WHEN r.r_reason_desc = 'Customer Not Satisfied' THEN 1 ELSE 0 END) AS reason_customer_not_satisfied_cnt,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_tickets,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE d.d_year = 2000
      AND i.i_brand = 'Brand#45'
      AND s.s_state = 'TN'
      AND ca.ca_country = 'United States'
      AND t.t_hour BETWEEN 9 AND 17
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 0
    GROUP BY s.s_store_id, d.d_year, d.d_month_seq
)
SELECT
    store_id,
    year,
    month_seq,
    store_sales_net_paid,
    web_sales_net_paid,
    (store_sales_net_paid + web_sales_net_paid) AS total_sales_net_paid,
    (store_sales_quantity + web_sales_quantity) AS total_quantity,
    inventory_on_hand,
    total_promo_cost,
    reason_customer_not_satisfied_cnt,
    store_sales_tickets,
    web_sales_orders,
    (store_sales_net_paid - store_returns_net_loss + web_sales_net_paid - web_returns_net_loss) AS net_profit_after_returns
FROM agg_sales
WHERE (store_sales_net_paid + web_sales_net_paid) > 100000
ORDER BY total_sales_net_paid DESC
LIMIT 100
