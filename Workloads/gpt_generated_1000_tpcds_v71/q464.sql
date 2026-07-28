WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        SUM(ws.ws_net_paid) AS web_sales_amount,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(ws.ws_net_paid) - SUM(sr.sr_return_amt) AS net_amount
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk               -- web sales date
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk          -- bill‑to customer
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk      -- store return date
    WHERE d_ws.d_year = 2001
      AND i.i_current_price > 100
      AND cd.cd_education_status = 'College'
      AND p.p_promo_name LIKE '%Holiday%'
      AND sm.sm_carrier = 'FEDEX'
    GROUP BY c.c_customer_id, i.i_item_id
)
SELECT DISTINCT
    c_customer_id,
    i_item_id,
    net_amount,
    RANK() OVER (PARTITION BY c_customer_id ORDER BY net_amount DESC) AS rank_per_customer
FROM sales_agg
ORDER BY net_amount DESC
LIMIT 100
