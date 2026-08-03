WITH base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        c.c_customer_sk AS cust_sk,
        c.c_customer_id,
        ca_refunded.ca_city AS refunded_city,
        ca_returning.ca_city AS returning_city,
        cd_refunded.cd_gender AS refunded_gender,
        cd_returning.cd_gender AS returning_gender,
        hd_refunded.hd_income_band_sk AS refunded_income_band,
        hd_returning.hd_income_band_sk AS returning_income_band,
        sm.sm_type,
        w.w_warehouse_name,
        inv.inv_quantity_on_hand,
        ws.ws_net_paid,
        ws.ws_quantity,
        p.p_promo_id,
        wp.wp_url,
        ws2.web_site_id,
        s.s_store_name,
        sr.sr_return_quantity,
        sr.sr_net_loss
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws2
        ON ws.ws_web_site_sk = ws2.web_site_sk
    FULL OUTER JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    FULL OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
)
SELECT
    base.cr_order_number,
    base.c_customer_id,
    base.refunded_city,
    base.returning_city,
    base.refunded_gender,
    base.returning_gender,
    base.refunded_income_band,
    base.returning_income_band,
    base.sm_type,
    base.w_warehouse_name,
    base.inv_quantity_on_hand,
    base.ws_net_paid,
    base.ws_quantity,
    base.p_promo_id,
    base.wp_url,
    base.web_site_id,
    base.s_store_name,
    base.sr_return_quantity,
    base.sr_net_loss,
    (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = base.cust_sk
    ) AS cust_return_count
FROM base
WHERE base.cr_order_number NOT IN (
    SELECT cr2.cr_order_number
    FROM catalog_returns cr2
    WHERE cr2.cr_return_amount > 1000
)
  AND base.cust_sk IN (
        SELECT c3.c_customer_sk FROM customer c3
        INTERSECT
        SELECT ws3.ws_bill_customer_sk FROM web_sales ws3
    )
LIMIT 100
