WITH joined_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        p.p_promo_id,
        p.p_discount_active,
        sm.sm_ship_mode_id,
        sm.sm_code,
        wp.wp_web_page_id,
        ws_site.web_site_id,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        c_bill.c_customer_id AS bill_customer_id,
        c_ship.c_customer_id AS ship_customer_id,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_amt_inc_tax,
        cp.cp_catalog_number,
        cp.cp_description,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        ca_current.ca_state AS current_addr_state,
        c_wp.c_customer_id AS wp_customer_id
    FROM web_sales ws
    INNER JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    INNER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    INNER JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    INNER JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    INNER JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    LEFT JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    LEFT JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN customer c_wp
        ON wp.wp_customer_sk = c_wp.c_customer_sk
    LEFT JOIN customer_address ca_current
        ON c_bill.c_current_addr_sk = ca_current.ca_address_sk
    LEFT JOIN customer c_sr_customer
        ON sr.sr_customer_sk = c_sr_customer.c_customer_sk
    LEFT JOIN customer_address ca_sr_addr
        ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
        AND i.i_brand = 'Brand#12'
        AND sm.sm_code = 'AIR'
        AND p.p_discount_active = 'Y'
        AND ca_bill.ca_state = 'CA'
        AND EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_item_sk = i.i_item_sk
              AND sr2.sr_net_loss > 500
        )
),
item_agg AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_category,
        i_brand,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_ext_discount_amt) AS avg_discount,
        SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_return_amount,
        SUM(COALESCE(sr_return_amt, 0)) AS total_store_return_amount,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        COUNT(DISTINCT CASE WHEN ws_net_profit > 0 THEN ws_order_number END) AS profit_orders,
        CASE
            WHEN SUM(ws_net_profit) > 0 THEN 'PROFITABLE'
            ELSE 'UNPROFITABLE'
        END AS profitability_flag
    FROM joined_data
    GROUP BY i_item_sk, i_item_id, i_category, i_brand
)
SELECT
    i_item_id,
    i_category,
    i_brand,
    total_quantity_sold,
    total_net_paid,
    total_net_profit,
    profitability_flag,
    avg_discount,
    total_catalog_return_amount,
    total_store_return_amount,
    distinct_orders,
    (SELECT AVG(ws_ext_discount_amt)
     FROM web_sales ws2
     WHERE ws2.ws_sold_date_sk BETWEEN 2450000 AND 2452000) AS overall_avg_discount
FROM item_agg
WHERE
    total_store_return_amount > 1000
    AND total_catalog_return_amount > 500
    AND total_net_profit > 0
    AND distinct_orders >= 5
ORDER BY total_net_profit DESC
LIMIT 100
