WITH filtered_store_returns AS (
    SELECT sr.sr_customer_sk,
           sr.sr_item_sk,
           sr.sr_refunded_cash,
           sr.sr_return_ship_cost,
           r.r_reason_desc
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
      AND sr.sr_refunded_cash > 100
      AND ca.ca_state = 'CA'
      AND i.i_current_price > 50
      AND sr.sr_return_ship_cost < 500
),
joined_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        c_bill.c_customer_id AS customer_id,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        i.i_current_price,
        i.i_category,
        w.w_gmt_offset,
        sm.sm_type,
        ws_site.web_name,
        wr.wr_return_amt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451400 AND 2451500
      AND i.i_category = 'Electronics'
      AND sm.sm_type = 'Standard'
      AND w.w_gmt_offset > 0
      AND ca_bill.ca_state = 'CA'
      AND i.i_current_price > 100
      AND EXISTS (
          SELECT 1
          FROM filtered_store_returns f
          WHERE f.sr_customer_sk = ws.ws_bill_customer_sk
            AND f.sr_item_sk = ws.ws_item_sk
      )
),
aggregated AS (
    SELECT
        jd.customer_id,
        jd.web_name,
        SUM(jd.ws_net_profit) AS total_net_profit,
        SUM(COALESCE(fsr.sr_refunded_cash, 0)) AS total_store_refunded_cash,
        COUNT(DISTINCT jd.ws_order_number) AS orders_count,
        AVG(jd.wr_return_amt) AS avg_web_return_amt
    FROM joined_data jd
    LEFT JOIN filtered_store_returns fsr
        ON fsr.sr_customer_sk = jd.ws_bill_customer_sk
        AND fsr.sr_item_sk = jd.ws_item_sk
    GROUP BY jd.customer_id, jd.web_name
    HAVING SUM(jd.ws_net_profit) > 1000
       AND COUNT(DISTINCT jd.ws_order_number) >= 5
       AND SUM(COALESCE(fsr.sr_refunded_cash, 0)) < 5000
       AND AVG(jd.wr_return_amt) > 10
       AND MAX(COALESCE(fsr.sr_refunded_cash, 0)) > 0
)
SELECT
    a.customer_id,
    a.web_name,
    a.total_net_profit,
    a.total_store_refunded_cash,
    a.orders_count,
    a.avg_web_return_amt,
    RANK() OVER (PARTITION BY a.web_name ORDER BY a.total_net_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY profit_rank
LIMIT 100
