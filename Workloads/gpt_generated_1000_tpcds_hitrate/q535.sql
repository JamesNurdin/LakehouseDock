WITH inventory_agg AS (
    SELECT inv_warehouse_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_warehouse_sk, inv_date_sk
),
warehouse_excluding AS (
    SELECT w_warehouse_sk
    FROM warehouse
    EXCEPT
    SELECT ws_warehouse_sk
    FROM web_sales
)
SELECT
    ws.ws_order_number,
    d.d_date,
    ca.ca_city,
    webs.web_name,
    ws.ws_warehouse_sk,
    iag.total_qty,
    ws.ws_net_profit,
    CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    ws.ws_net_profit / NULLIF(ws.ws_ext_sales_price, 0) AS profit_margin,
    LAG(ws.ws_net_profit) OVER (PARTITION BY ws.ws_warehouse_sk ORDER BY d.d_date) AS prev_day_profit,
    (
        SELECT AVG(ws2.ws_net_paid)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2002
    ) AS avg_net_paid_2002
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN inventory_agg iag ON iag.inv_warehouse_sk = ws.ws_warehouse_sk
    AND iag.inv_date_sk = ws.ws_sold_date_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
WHERE
    d.d_year = 2002
    AND ca.ca_state = 'CA'
    AND ib.ib_upper_bound > 50000
    AND p.p_discount_active = 'Y'
    AND webs.web_country = 'United States'
    AND sm.sm_type = 'REGULAR'
    AND (iag.total_qty IS NULL OR iag.total_qty > 100)
    AND ws.ws_warehouse_sk NOT IN (SELECT w_warehouse_sk FROM warehouse_excluding)
ORDER BY d.d_date, ws.ws_warehouse_sk
LIMIT 100
