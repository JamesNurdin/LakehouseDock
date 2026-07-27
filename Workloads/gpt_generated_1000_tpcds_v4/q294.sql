WITH returns_agg AS (
    SELECT 
        wr_order_number,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_returned_date_sk >= 2450000
      AND wr_return_amt > 0
      AND wr_return_quantity >= 1
    GROUP BY wr_order_number
)
SELECT
    ws.ws_order_number,
    c_bill.c_customer_id,
    ca_bill.ca_city,
    sm.sm_type,
    w.w_warehouse_name,
    p.p_promo_name,
    ws.ws_net_profit,
    ra.total_return_amt,
    ra.return_cnt,
    RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM web_sales ws
JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
JOIN returns_agg ra
    ON ws.ws_order_number = ra.wr_order_number
WHERE sm.sm_type = 'OVERNIGHT'
  AND p.p_discount_active = 'Y'
  AND ws.ws_ext_ship_cost > 500
  AND c_bill.c_birth_year BETWEEN 1950 AND 1960
ORDER BY profit_rank, ws.ws_order_number
LIMIT 100
