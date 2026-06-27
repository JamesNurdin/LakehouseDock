WITH
  sales_agg AS (
    /* Store sales */
    SELECT
      d.d_year,
      d.d_moy,
      ca.ca_state,
      'store' AS channel,
      SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, ca.ca_state
    UNION ALL
    /* Catalog sales */
    SELECT
      d.d_year,
      d.d_moy,
      ca.ca_state,
      'catalog' AS channel,
      SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, ca.ca_state
    UNION ALL
    /* Web sales */
    SELECT
      d.d_year,
      d.d_moy,
      ca.ca_state,
      'web' AS channel,
      SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, ca.ca_state
  ),
  returns_agg AS (
    /* Store returns */
    SELECT
      d.d_year,
      d.d_moy,
      ca.ca_state,
      'store' AS channel,
      SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, ca.ca_state
    UNION ALL
    /* Catalog returns */
    SELECT
      d.d_year,
      d.d_moy,
      ca.ca_state,
      'catalog' AS channel,
      SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, ca.ca_state
    UNION ALL
    /* Web returns */
    SELECT
      d.d_year,
      d.d_moy,
      ca.ca_state,
      'web' AS channel,
      SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, ca.ca_state
  )
SELECT
  s.d_year,
  s.d_moy,
  s.ca_state,
  s.channel,
  s.total_net_profit,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
 AND s.d_moy = r.d_moy
 AND s.ca_state = r.ca_state
 AND s.channel = r.channel
ORDER BY s.d_year, s.d_moy, s.ca_state, s.channel
