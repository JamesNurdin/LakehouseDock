WITH joined AS (
    SELECT
        ws.ws_order_number               AS order_number,
        ws.ws_quantity                  AS quantity,
        ws.ws_net_profit                AS net_profit,
        ws_site.web_name                AS web_name,
        d_sales.d_year                  AS sale_year,
        p.p_promo_id                    AS promo_id,
        p.p_channel_dmail               AS channel_dmail,
        p.p_discount_active             AS discount_active,
        cc.cc_name                      AS call_center_name,
        cc.cc_state                     AS call_center_state,
        cp.cp_description               AS page_desc,
        ca_bill.ca_state                AS bill_state,
        inv.inv_quantity_on_hand        AS inventory_on_hand,
        cr.cr_return_amount             AS return_amount,
        CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS discount_active_flag
    FROM web_sales ws
    JOIN date_dim d_sales
      ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site ws_site
      ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN customer_address ca_bill
      ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN catalog_returns cr
      ON cr.cr_refunded_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_refund
      ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory inv
      ON inv.inv_date_sk = d_sales.d_date_sk
    WHERE p.p_channel_dmail = 'Y'
      AND d_sales.d_fy_quarter_seq = 16
      AND cc.cc_state = 'CA'
      AND ws.ws_quantity > 10
      AND cp.cp_description LIKE '%women%'
)
SELECT DISTINCT
    order_number,
    web_name,
    sale_year,
    net_profit,
    discount_active_flag,
    RANK() OVER (PARTITION BY web_name ORDER BY net_profit DESC) AS profit_rank
FROM joined
ORDER BY profit_rank, net_profit DESC
LIMIT 100
