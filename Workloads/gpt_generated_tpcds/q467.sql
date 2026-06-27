WITH
  store_sales_agg AS (
    SELECT
      ca.ca_state AS state,
      SUM(ss.ss_net_profit) AS profit,
      SUM(ss.ss_quantity) AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
  ),
  catalog_sales_agg AS (
    SELECT
      ca.ca_state AS state,
      SUM(cs.cs_net_profit) AS profit,
      SUM(cs.cs_quantity) AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
  ),
  web_sales_agg AS (
    SELECT
      ca.ca_state AS state,
      SUM(ws.ws_net_profit) AS profit,
      SUM(ws.ws_quantity) AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
  ),
  store_returns_agg AS (
    SELECT
      ca.ca_state AS state,
      SUM(sr.sr_net_loss) AS loss,
      SUM(sr.sr_return_quantity) AS return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
  ),
  catalog_returns_agg AS (
    SELECT
      ca.ca_state AS state,
      SUM(cr.cr_net_loss) AS loss,
      SUM(cr.cr_return_quantity) AS return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
  ),
  web_returns_agg AS (
    SELECT
      ca.ca_state AS state,
      SUM(wr.wr_net_loss) AS loss,
      SUM(wr.wr_return_quantity) AS return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY ca.ca_state
  ),
  sales_agg AS (
    SELECT
      state,
      SUM(profit) AS total_profit,
      SUM(quantity) AS total_quantity
    FROM (
      SELECT state, profit, quantity FROM store_sales_agg
      UNION ALL
      SELECT state, profit, quantity FROM catalog_sales_agg
      UNION ALL
      SELECT state, profit, quantity FROM web_sales_agg
    ) s
    GROUP BY state
  ),
  returns_agg AS (
    SELECT
      state,
      SUM(loss) AS total_loss,
      SUM(return_qty) AS total_return_qty
    FROM (
      SELECT state, loss, return_qty FROM store_returns_agg
      UNION ALL
      SELECT state, loss, return_qty FROM catalog_returns_agg
      UNION ALL
      SELECT state, loss, return_qty FROM web_returns_agg
    ) r
    GROUP BY state
  )
SELECT
  s.state,
  s.total_profit - COALESCE(r.total_loss, 0) AS net_profit,
  s.total_quantity AS total_sales_quantity,
  COALESCE(r.total_return_qty, 0) AS total_return_quantity,
  s.total_profit AS total_sales_profit,
  COALESCE(r.total_loss, 0) AS total_return_loss
FROM sales_agg s
LEFT JOIN returns_agg r ON s.state = r.state
ORDER BY net_profit DESC
LIMIT 20
