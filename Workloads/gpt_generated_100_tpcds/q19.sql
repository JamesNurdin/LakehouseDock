WITH catalog_loss AS (
    SELECT ca.ca_state AS state,
           SUM(cr.cr_net_loss) AS catalog_return_loss
    FROM catalog_returns cr
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
store_loss AS (
    SELECT ca.ca_state AS state,
           SUM(sr.sr_net_loss) AS store_return_loss
    FROM store_returns sr
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
web_return_loss AS (
    SELECT ca.ca_state AS state,
           SUM(wr.wr_net_loss) AS web_return_loss
    FROM web_returns wr
    JOIN customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
web_sales_profit AS (
    SELECT ca.ca_state AS state,
           SUM(ws.ws_net_profit) AS web_sales_profit
    FROM web_sales ws
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
)
SELECT COALESCE(ca.state, sl.state, wr.state, ws.state) AS state,
       COALESCE(catalog_return_loss, 0)      AS catalog_return_loss,
       COALESCE(store_return_loss, 0)        AS store_return_loss,
       COALESCE(web_return_loss, 0)          AS web_return_loss,
       COALESCE(web_sales_profit, 0)         AS web_sales_profit,
       (COALESCE(web_sales_profit, 0)
        - COALESCE(catalog_return_loss, 0)
        - COALESCE(store_return_loss, 0)
        - COALESCE(web_return_loss, 0))      AS net_profit_after_returns
FROM catalog_loss ca
FULL OUTER JOIN store_loss sl
  ON ca.state = sl.state
FULL OUTER JOIN web_return_loss wr
  ON COALESCE(ca.state, sl.state) = wr.state
FULL OUTER JOIN web_sales_profit ws
  ON COALESCE(ca.state, sl.state, wr.state) = ws.state
ORDER BY state
