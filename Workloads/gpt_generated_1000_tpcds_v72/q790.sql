WITH sub1 AS (
    SELECT
        s.s_store_name,
        i1.i_category,
        SUM(ss.ss_net_paid) AS store_sales_total,
        SUM(ws.ws_net_paid) AS web_sales_total,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn
    FROM
        store_sales ss
        JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
        JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
        JOIN customer_address ca_return ON sr.sr_addr_sk = ca_return.ca_address_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i2.i_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
        JOIN web_sales ws ON ws.ws_item_sk = i2.i_item_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
        JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    WHERE
        s.s_state = 'CA'
        AND i1.i_class = 'decor'
    GROUP BY
        s.s_store_name,
        i1.i_category
),
sub2 AS (
    SELECT
        s.s_store_name,
        i1.i_category,
        SUM(ss.ss_net_paid) AS store_sales_total,
        SUM(ws.ws_net_paid) AS web_sales_total,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn
    FROM
        store_sales ss
        JOIN item i1 ON ss.ss_item_sk = i1.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p1 ON ss.ss_promo_sk = p1.p_promo_sk
        JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
        JOIN customer_address ca_return ON sr.sr_addr_sk = ca_return.ca_address_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i2.i_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
        JOIN web_sales ws ON ws.ws_item_sk = i2.i_item_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
        JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    WHERE
        s.s_state = 'TX'
        AND i1.i_class = 'shirts'
    GROUP BY
        s.s_store_name,
        i1.i_category
)
SELECT *
FROM sub1
UNION ALL
SELECT *
FROM sub2
ORDER BY store_sales_total DESC
LIMIT 100
