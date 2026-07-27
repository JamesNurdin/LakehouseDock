WITH sales_cte AS (
  SELECT
    ca.ca_state AS state,
    'sale' AS record_type,
    SUM(ws.ws_net_profit) AS metric_amount1,
    SUM(ws.ws_ext_sales_price) AS metric_amount2,
    COUNT(DISTINCT ws.ws_order_number) AS cnt
  FROM tpcds.web_sales ws
  JOIN tpcds.customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE p.p_channel_email = 'Y'
    AND EXISTS (
      SELECT 1 FROM tpcds.promotion p2
      WHERE p2.p_promo_sk = ws.ws_promo_sk
        AND p2.p_discount_active = 'Y'
    )
  GROUP BY ca.ca_state
),
returns_cte AS (
  SELECT
    ca.ca_state AS state,
    'return' AS record_type,
    SUM(wr.wr_net_loss) AS metric_amount1,
    SUM(wr.wr_return_amt) AS metric_amount2,
    COUNT(DISTINCT wr.wr_order_number) AS cnt
  FROM tpcds.web_returns wr
  JOIN tpcds.customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_desc LIKE '%damaged%'
  GROUP BY ca.ca_state
)
SELECT DISTINCT state, record_type, metric_amount1, metric_amount2, cnt
FROM sales_cte
UNION ALL
SELECT DISTINCT state, record_type, metric_amount1, metric_amount2, cnt
FROM returns_cte
ORDER BY state, record_type
LIMIT 100
