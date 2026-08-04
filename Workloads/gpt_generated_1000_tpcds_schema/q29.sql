WITH base AS (
    SELECT
        d.d_year,
        w.w_city,
        r.r_reason_desc,
        ws.ws_net_paid,
        ws.ws_order_number,
        i.i_current_price,
        sr.sr_return_amt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 1902
      AND w.w_city = 'Liberty'
      AND r.r_reason_desc LIKE '%did not like%'
      AND ws.ws_net_paid > (
          SELECT MAX(sr2.sr_return_amt) FROM store_returns sr2
      )
),
agg AS (
    SELECT
        d_year,
        w_city,
        r_reason_desc,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS order_cnt,
        AVG(i_current_price) AS avg_item_price,
        MAX(sr_return_amt) AS max_return_amount
    FROM base
    GROUP BY d_year, w_city, r_reason_desc
)
SELECT
    d_year,
    w_city,
    r_reason_desc,
    total_net_paid,
    order_cnt,
    avg_item_price,
    max_return_amount,
    LAG(total_net_paid) OVER (PARTITION BY w_city ORDER BY d_year) AS lag_total_net_paid
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
