WITH sr_agg AS (
    SELECT
        sr_addr_sk,
        sr_reason_sk,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_amt) AS avg_return_amt,
        COUNT(*) AS cnt_returns
    FROM store_returns
    WHERE sr_return_quantity > 1
      AND sr_return_amt > 10
      AND sr_return_tax BETWEEN 0 AND 5
    GROUP BY sr_addr_sk, sr_reason_sk
),
distinct_ws AS (
    SELECT DISTINCT
        ws_bill_addr_sk,
        ws_warehouse_sk,
        ws_order_number,
        ws_net_paid_inc_ship_tax,
        ws_coupon_amt
    FROM web_sales
    WHERE ws_coupon_amt > 100
      AND ws_net_paid_inc_ship_tax BETWEEN 1000 AND 5000
)
SELECT
    ca.ca_city,
    ca.ca_state,
    w.w_warehouse_name,
    r.r_reason_desc,
    SUM(sr_agg.total_return_amt) AS sum_return_amt,
    AVG(distinct_ws.ws_net_paid_inc_ship_tax) AS avg_net_paid_inc_ship_tax,
    COUNT(DISTINCT distinct_ws.ws_order_number) AS distinct_orders,
    MIN(distinct_ws.ws_coupon_amt) AS min_coupon_amt,
    MAX(distinct_ws.ws_coupon_amt) AS max_coupon_amt
FROM sr_agg
JOIN customer_address ca ON sr_agg.sr_addr_sk = ca.ca_address_sk
JOIN reason r ON sr_agg.sr_reason_sk = r.r_reason_sk
JOIN distinct_ws ON distinct_ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN warehouse w ON distinct_ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ca.ca_location_type = 'apartment'
  AND ca.ca_gmt_offset = -6.00
  AND w.w_warehouse_name LIKE 'Local%'
  AND r.r_reason_desc = 'Damaged'
GROUP BY ca.ca_city, ca.ca_state, w.w_warehouse_name, r.r_reason_desc
ORDER BY sum_return_amt DESC
LIMIT 100
