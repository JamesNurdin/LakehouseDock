WITH yearly_state_promo AS (
    SELECT
        d.d_year,
        w.w_state,
        p.p_promo_name,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ss.ss_net_profit + cs.cs_net_profit + ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_store_sales,
        COUNT(DISTINCT cs.cs_order_number) AS num_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_web_sales
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 5
      AND sr.sr_refunded_cash > 100.0
      AND ca.ca_country = 'United States'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr_check
          WHERE sr_check.sr_ticket_number = ss.ss_ticket_number
            AND sr_check.sr_refunded_cash > 200.0
      )
    GROUP BY d.d_year, w.w_state, p.p_promo_name
)
SELECT DISTINCT
    ysp.d_year,
    ysp.w_state,
    ysp.p_promo_name,
    ysp.total_profit,
    (SELECT AVG(total_profit) FROM yearly_state_promo ysp2 WHERE ysp2.w_state = ysp.w_state) AS avg_state_profit
FROM yearly_state_promo ysp
WHERE ysp.total_profit > (SELECT AVG(total_profit) FROM yearly_state_promo)
ORDER BY ysp.total_profit DESC
LIMIT 100
