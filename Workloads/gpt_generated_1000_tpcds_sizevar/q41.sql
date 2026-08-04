WITH base AS (
    SELECT
        wsit.web_name,
        sm.sm_type,
        p.p_promo_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_quantity
    FROM promotion p
    RIGHT OUTER JOIN web_sales ws
        ON p.p_promo_sk = ws.ws_promo_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE wsit.web_name IN ('site_0', 'site_1')
      AND sm.sm_code = 'AIR'
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2450845
    GROUP BY ROLLUP (wsit.web_name, sm.sm_type, p.p_promo_name)
)
SELECT
    web_name,
    sm_type,
    p_promo_name,
    total_sales,
    total_net_paid,
    total_quantity,
    ROW_NUMBER() OVER (PARTITION BY web_name ORDER BY total_sales DESC) AS site_rank
FROM base
ORDER BY web_name, sm_type, p_promo_name
LIMIT 100
