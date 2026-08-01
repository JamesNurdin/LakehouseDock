WITH
store_sample AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           s.s_state,
           s.s_rec_start_date
    FROM store s
    TABLESAMPLE BERNOULLI (10)
    WHERE s.s_rec_start_date >= DATE '1998-01-01'
),
sr_join AS (
    SELECT sr.sr_returned_date_sk,
           sr.sr_return_time_sk,
           sr.sr_item_sk,
           sr.sr_customer_sk,
           sr.sr_cdemo_sk,
           sr.sr_hdemo_sk,
           sr.sr_addr_sk,
           sr.sr_store_sk,
           sr.sr_reason_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt,
           sr.sr_return_tax,
           sr.sr_return_amt_inc_tax,
           sr.sr_fee,
           sr.sr_return_ship_cost,
           sr.sr_refunded_cash,
           sr.sr_reversed_charge,
           sr.sr_store_credit,
           sr.sr_net_loss,
           t.t_hour,
           t.t_shift,
           ca.ca_state,
           ca.ca_city,
           s.s_store_name,
           s.s_state
    FROM store_returns sr
    LEFT JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sample s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_net_loss < 500
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_item_sk = sr.sr_item_sk
            AND ws.ws_sold_time_sk = sr.sr_return_time_sk
      )
),
cr_join AS (
    SELECT cr.cr_returned_date_sk,
           cr.cr_returned_time_sk,
           cr.cr_item_sk,
           cr.cr_refunded_customer_sk,
           cr.cr_refunded_cdemo_sk,
           cr.cr_refunded_hdemo_sk,
           cr.cr_refunded_addr_sk,
           cr.cr_returning_customer_sk,
           cr.cr_returning_cdemo_sk,
           cr.cr_returning_hdemo_sk,
           cr.cr_returning_addr_sk,
           cr.cr_call_center_sk,
           cr.cr_warehouse_sk,
           cr.cr_reason_sk,
           cr.cr_order_number,
           cr.cr_return_quantity,
           cr.cr_return_amount,
           cr.cr_return_tax,
           cr.cr_return_amt_inc_tax,
           cr.cr_fee,
           cr.cr_return_ship_cost,
           cr.cr_refunded_cash,
           cr.cr_reversed_charge,
           cr.cr_store_credit,
           cr.cr_net_loss,
           t.t_hour AS cr_hour,
           t.t_shift AS cr_shift,
           ca_ref.ca_state AS refunded_state,
           ca_ref.ca_city AS refunded_city,
           ca_re.ca_state AS returning_state,
           ca_re.ca_city AS returning_city,
           cc.cc_name,
           cc.cc_rec_start_date,
           w.w_warehouse_name,
           w.w_warehouse_sq_ft
    FROM catalog_returns cr
    LEFT JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    LEFT JOIN customer_address ca_re
        ON cr.cr_returning_addr_sk = ca_re.ca_address_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_rec_start_date >= DATE '2001-01-01'
      AND w.w_warehouse_sq_ft > 10000
),
ws_join AS (
    SELECT ws.ws_sold_date_sk,
           ws.ws_sold_time_sk,
           ws.ws_ship_date_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           ws.ws_bill_cdemo_sk,
           ws.ws_bill_hdemo_sk,
           ws.ws_bill_addr_sk,
           ws.ws_ship_customer_sk,
           ws.ws_ship_cdemo_sk,
           ws.ws_ship_hdemo_sk,
           ws.ws_ship_addr_sk,
           ws.ws_web_page_sk,
           ws.ws_web_site_sk,
           ws.ws_ship_mode_sk,
           ws.ws_warehouse_sk,
           ws.ws_promo_sk,
           ws.ws_order_number,
           ws.ws_quantity,
           ws.ws_wholesale_cost,
           ws.ws_list_price,
           ws.ws_sales_price,
           ws.ws_ext_discount_amt,
           ws.ws_ext_sales_price,
           ws.ws_ext_wholesale_cost,
           ws.ws_ext_list_price,
           ws.ws_ext_tax,
           ws.ws_coupon_amt,
           ws.ws_ext_ship_cost,
           ws.ws_net_paid,
           ws.ws_net_paid_inc_tax,
           ws.ws_net_paid_inc_ship,
           ws.ws_net_paid_inc_ship_tax,
           ws.ws_net_profit,
           t.t_hour AS ws_hour,
           t.t_shift AS ws_shift,
           ca_bill.ca_city AS bill_city,
           ca_bill.ca_state AS bill_state,
           ca_ship.ca_city AS ship_city,
           ca_ship.ca_state AS ship_state,
           w.w_warehouse_name,
           w.w_warehouse_sq_ft
    FROM web_sales ws
    LEFT JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_list_price > 50
),
union_set AS (
    SELECT
        sr_returned_date_sk AS event_date_sk,
        sr_return_time_sk AS event_time_sk,
        sr_return_amt AS amount,
        'store_return' AS source,
        s_store_name AS location_name,
        s_state AS location_state,
        sr_return_quantity AS quantity,
        sr_net_loss AS net_loss,
        sr_return_ship_cost AS ship_cost
    FROM sr_join
    UNION
    SELECT
        ws_sold_date_sk AS event_date_sk,
        ws_sold_time_sk AS event_time_sk,
        ws_sales_price AS amount,
        'web_sale' AS source,
        w_warehouse_name AS location_name,
        NULL AS location_state,
        ws_quantity AS quantity,
        ws_net_profit AS net_loss,
        ws_ext_ship_cost AS ship_cost
    FROM ws_join
)
SELECT
    COALESCE(u.event_date_sk, c.cr_returned_date_sk) AS event_date_sk,
    COALESCE(u.event_time_sk, c.cr_returned_time_sk) AS event_time_sk,
    COALESCE(u.source, 'catalog_return') AS source,
    COALESCE(u.location_name, c.w_warehouse_name) AS location_name,
    COALESCE(u.location_state, c.refunded_state) AS location_state,
    COALESCE(u.amount, c.cr_return_amount) AS amount,
    COALESCE(u.quantity, c.cr_return_quantity) AS quantity,
    COALESCE(u.net_loss, c.cr_net_loss) AS net_loss,
    COALESCE(u.ship_cost, c.cr_return_ship_cost) AS ship_cost,
    CASE
        WHEN COALESCE(u.amount, c.cr_return_amount) > 1000 THEN 'High'
        WHEN COALESCE(u.amount, c.cr_return_amount) > 500 THEN 'Medium'
        ELSE 'Low'
    END AS amount_category,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(u.source, 'catalog_return')
        ORDER BY COALESCE(u.amount, c.cr_return_amount) DESC
    ) AS rn,
    SUM(COALESCE(u.amount, c.cr_return_amount)) OVER (
        PARTITION BY COALESCE(u.source, 'catalog_return')
        ORDER BY COALESCE(u.event_date_sk, c.cr_returned_date_sk)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,
    (SELECT COUNT(*) FROM catalog_returns cr3 WHERE cr3.cr_return_quantity > 0) AS total_catalog_returns
FROM union_set u
FULL OUTER JOIN cr_join c
    ON u.event_time_sk = c.cr_returned_time_sk
WHERE
    (COALESCE(u.location_state, c.refunded_state) = 'CA'
     OR COALESCE(u.location_state, c.returning_state) = 'CA')
    AND COALESCE(u.amount, c.cr_return_amount) IS NOT NULL
    AND COALESCE(u.event_date_sk, c.cr_returned_date_sk) BETWEEN 2451200 AND 2451300
    AND COALESCE(u.quantity, c.cr_return_quantity) > 0
    AND COALESCE(u.net_loss, c.cr_net_loss) < 1000
ORDER BY rn
LIMIT 100
