WITH
  ws_agg AS (
    SELECT
      w.w_warehouse_name AS entity_name,
      SUM(ws.ws_net_profit) AS metric_value
    FROM
      web_sales ws
      INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
      ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY
      w.w_warehouse_name
  ),
  ws_ranked AS (
    SELECT
      'Warehouse' AS entity_type,
      entity_name,
      metric_value,
      RANK() OVER (ORDER BY metric_value DESC) AS metric_rank
    FROM
      ws_agg
  ),
  wr_agg AS (
    SELECT
      ca.ca_county AS entity_name,
      SUM(wr.wr_return_amt) AS metric_value
    FROM
      web_returns wr
      INNER JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE
      wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY
      ca.ca_county
  ),
  wr_ranked AS (
    SELECT
      'County' AS entity_type,
      entity_name,
      metric_value,
      RANK() OVER (ORDER BY metric_value DESC) AS metric_rank
    FROM
      wr_agg
  )
SELECT
  entity_type,
  entity_name,
  metric_value,
  metric_rank
FROM
  ws_ranked
UNION ALL
SELECT
  entity_type,
  entity_name,
  metric_value,
  metric_rank
FROM
  wr_ranked
ORDER BY
  entity_type,
  metric_rank
