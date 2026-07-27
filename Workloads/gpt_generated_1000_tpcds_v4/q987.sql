WITH joined AS (
    SELECT
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_color,
        i.i_current_price,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss AS wr_net_loss,
        p.p_promo_name,
        sm.sm_type,
        r.r_reason_desc,
        r2.r_reason_desc AS store_return_reason,
        r3.r_reason_desc AS web_return_reason,
        t.t_hour,
        we.web_name,
        we.web_city,
        we.web_state,
        cp.cp_department,
        cp.cp_type,
        ca.ca_city,
        cd.cd_gender
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN reason r2
        ON sr.sr_reason_sk = r2.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r3
        ON wr.wr_reason_sk = r3.r_reason_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sales_price > 0
      AND cr.cr_return_amount > 100
      AND i.i_current_price BETWEEN 50 AND 500
      AND we.web_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ws.ws_promo_sk
            AND p2.p_discount_active = 'Y'
      )
),
agg AS (
    SELECT
        i_category,
        p_promo_name,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(sr_return_amt) AS total_store_return_amt,
        SUM(wr_return_amt) AS total_web_return_amt,
        COUNT(DISTINCT ws_order_number) AS orders_cnt,
        AVG(i_current_price) AS avg_item_price
    FROM joined
    GROUP BY i_category, p_promo_name
)
SELECT
    i_category,
    p_promo_name,
    total_net_profit,
    total_return_amount,
    total_store_return_amt,
    total_web_return_amt,
    orders_cnt,
    avg_item_price,
    total_net_profit / NULLIF(orders_cnt, 0) AS avg_profit_per_order
FROM agg
WHERE total_net_profit > 1000
  AND total_return_amount > 200
  AND orders_cnt >= 10
  AND avg_item_price < 400
ORDER BY total_net_profit DESC
LIMIT 100
