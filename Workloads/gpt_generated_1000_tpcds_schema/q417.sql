WITH sales_sample AS (
  SELECT
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ws.ws_quantity,
    sm.sm_type,
    sm.sm_carrier,
    c.c_first_name,
    c.c_last_name,
    wp.wp_web_page_id,
    wp.wp_max_ad_count,
    wr.wr_return_amt
  FROM web_sales ws
  TABLESAMPLE BERNOULLI (10)
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
  WHERE sm.sm_type IN ('NEXT DAY', 'EXPRESS')
    AND wp.wp_max_ad_count >= 2
    AND ws.ws_quantity > 2
),
order_return_arrays AS (
  SELECT
    ws_order_number,
    array_agg(wr_return_amt) FILTER (WHERE wr_return_amt IS NOT NULL) AS return_amt_array
  FROM sales_sample
  GROUP BY ws_order_number
),
final AS (
  SELECT
    ss.ws_order_number,
    ss.c_first_name,
    ss.c_last_name,
    ss.sm_type,
    ss.sm_carrier,
    ss.ws_ext_sales_price,
    ss.ws_net_profit,
    COALESCE(ra.return_amt_array, l.return_amt_array) AS return_amt_array,
    (
      SELECT SUM(r)
      FROM UNNEST(COALESCE(ra.return_amt_array, l.return_amt_array)) AS t(r)
    ) AS total_return_amt,
    RANK() OVER (PARTITION BY ss.sm_type ORDER BY ss.ws_net_profit DESC) AS profit_rank,
    EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_order_number = ss.ws_order_number
        AND wr.wr_return_amt > 500
    ) AS high_return_flag
  FROM sales_sample ss
  LEFT JOIN order_return_arrays ra
    ON ss.ws_order_number = ra.ws_order_number
  LEFT JOIN LATERAL (
    SELECT array_agg(wr.wr_return_amt) FILTER (WHERE wr.wr_return_amt IS NOT NULL) AS return_amt_array
    FROM web_returns wr
    WHERE wr.wr_order_number = ss.ws_order_number
  ) l ON TRUE
  WHERE ss.ws_net_profit > 0
)
SELECT
  ws_order_number,
  c_first_name,
  c_last_name,
  sm_type,
  sm_carrier,
  ws_ext_sales_price,
  ws_net_profit,
  total_return_amt,
  profit_rank,
  high_return_flag
FROM final
ORDER BY profit_rank ASC, ws_net_profit DESC
LIMIT 100
