WITH sales_agg AS (
    SELECT
        w.w_warehouse_name AS w_warehouse_name,
        p.p_promo_name AS p_promo_name,
        ca_ship.ca_state AS ship_state,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_rec_start_date >= DATE '2000-01-01'
      AND wp.wp_rec_end_date <= DATE '2002-12-31'
      AND wsit.web_zip = '49303'
      AND wsit.web_street_type = 'Road'
      AND p.p_discount_active = 'Y'
      AND ws.ws_quantity > 10
    GROUP BY ROLLUP (w.w_warehouse_name, p.p_promo_name, ca_ship.ca_state)
)
SELECT
    w_warehouse_name,
    p_promo_name,
    ship_state,
    total_net_profit,
    total_quantity,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY w_warehouse_name ORDER BY total_net_profit DESC) AS profit_rank,
    CASE WHEN total_net_profit > (SELECT AVG(total_net_profit) FROM sales_agg) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category
FROM sales_agg
WHERE w_warehouse_name IS NOT NULL
  AND p_promo_name IS NOT NULL
  AND ship_state IS NOT NULL
ORDER BY w_warehouse_name, profit_rank
LIMIT 100
