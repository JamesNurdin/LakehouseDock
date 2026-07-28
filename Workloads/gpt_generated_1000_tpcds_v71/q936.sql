WITH joined AS (
    SELECT
        ca.ca_state,
        p.p_promo_name,
        p.p_discount_active,
        sm.sm_type,
        ib.ib_lower_bound,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_order_number,
        cr.cr_return_amount,
        cr.cr_fee,
        sr.sr_return_amt,
        sr.sr_fee,
        wr.wr_return_amt,
        wr.wr_fee
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
      ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND ib.ib_lower_bound >= 50000
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450200
),
agg AS (
    SELECT
        ca_state,
        p_promo_name,
        SUM(cr_return_amount) AS sum_cr_return_amount,
        SUM(sr_return_amt) AS sum_sr_return_amt,
        SUM(wr_return_amt) AS sum_wr_return_amt,
        SUM(cr_fee) AS sum_cr_fee,
        SUM(sr_fee) AS sum_sr_fee,
        SUM(wr_fee) AS sum_wr_fee,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_quantity) AS avg_quantity,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM joined
    GROUP BY ROLLUP (ca_state, p_promo_name)
)
SELECT
    ca_state,
    p_promo_name,
    sum_cr_return_amount,
    sum_sr_return_amt,
    sum_wr_return_amt,
    (sum_cr_return_amount + sum_sr_return_amt + sum_wr_return_amt) AS total_return_amount,
    (sum_cr_fee + sum_sr_fee + sum_wr_fee) AS total_return_fee,
    total_net_profit,
    total_quantity,
    avg_quantity,
    distinct_orders,
    SUM(sum_cr_return_amount + sum_sr_return_amt + sum_wr_return_amt) OVER (
        PARTITION BY ca_state
        ORDER BY p_promo_name
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_state
FROM agg
ORDER BY ca_state, p_promo_name
LIMIT 100
