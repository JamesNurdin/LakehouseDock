WITH sales_summary AS (
    SELECT
        d.d_year,
        cc.cc_state,
        wsite.web_state,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN web_site wsite
        ON wsite.web_open_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE cc.cc_state = 'TX'
      AND cc.cc_employees > 50
      AND wsite.web_state = 'CA'
      AND d.d_year = 2002
      AND c.c_birth_month = 5
      AND ws.ws_net_profit > 1000
      AND inv.inv_quantity_on_hand < 300
      AND ws.ws_quantity >= 2
    GROUP BY d.d_year, cc.cc_state, wsite.web_state
)
SELECT
    d_year,
    cc_state,
    web_state,
    total_profit,
    total_quantity,
    avg_net_paid,
    total_profit / NULLIF(total_quantity, 0) AS profit_per_item
FROM sales_summary
WHERE total_profit > 5000
ORDER BY profit_per_item DESC
LIMIT 100
