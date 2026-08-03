WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
common_customers AS (
    SELECT sr.sr_customer_sk AS c_customer_sk
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 1
    INTERSECT
    SELECT ws.ws_bill_customer_sk AS c_customer_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 1
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_credit_rating,
    s.s_store_name,
    r_store.r_reason_desc AS store_return_reason,
    cr.cr_return_amount,
    ws.ws_net_paid,
    p.p_promo_name,
    inv_agg.total_qty_on_hand,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cr.cr_return_amount DESC) AS rn_return_amount,
    RANK() OVER (ORDER BY ws.ws_net_paid DESC) AS rank_total_paid,
    CASE
        WHEN cd.cd_credit_rating = 'Good' THEN 'Preferred'
        ELSE 'Regular'
    END AS customer_category
FROM common_customers cc
JOIN customer c
    ON cc.c_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_returning_customer_sk = c.c_customer_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc_center
    ON cr.cr_call_center_sk = cc_center.cc_call_center_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg
    ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
WHERE cd.cd_credit_rating IS NOT NULL
  AND s.s_state = 'CA'
  AND td.t_hour BETWEEN 9 AND 17
ORDER BY ws.ws_net_paid DESC
LIMIT 100
