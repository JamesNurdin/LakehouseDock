WITH
    store_sales_by_state AS (
        SELECT ca.ca_state AS state,
               SUM(ss.ss_net_profit) AS store_sales_profit
        FROM store_sales ss
        JOIN customer_address ca
          ON ss.ss_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    store_returns_by_state AS (
        SELECT ca.ca_state AS state,
               SUM(sr.sr_net_loss) AS store_returns_loss
        FROM store_returns sr
        JOIN store_sales ss
          ON sr.sr_ticket_number = ss.ss_ticket_number
         AND sr.sr_item_sk = ss.ss_item_sk
        JOIN customer_address ca
          ON ss.ss_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    web_sales_by_state AS (
        SELECT ca.ca_state AS state,
               SUM(ws.ws_net_profit) AS web_sales_profit
        FROM web_sales ws
        JOIN customer_address ca
          ON ws.ws_bill_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    web_returns_by_state AS (
        SELECT ca.ca_state AS state,
               SUM(wr.wr_net_loss) AS web_returns_loss
        FROM web_returns wr
        JOIN web_sales ws
          ON wr.wr_order_number = ws.ws_order_number
         AND wr.wr_item_sk = ws.ws_item_sk
        JOIN customer_address ca
          ON ws.ws_bill_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    ),
    catalog_sales_by_state AS (
        SELECT ca.ca_state AS state,
               SUM(cs.cs_net_profit) AS catalog_sales_profit
        FROM catalog_sales cs
        JOIN customer_address ca
          ON cs.cs_bill_addr_sk = ca.ca_address_sk
        GROUP BY ca.ca_state
    )
SELECT
    COALESCE(ss.state, sr.state, ws.state, wr.state, cs.state) AS state,
    COALESCE(ss.store_sales_profit, 0) AS store_sales_profit,
    COALESCE(sr.store_returns_loss, 0) AS store_returns_loss,
    COALESCE(ws.web_sales_profit, 0) AS web_sales_profit,
    COALESCE(wr.web_returns_loss, 0) AS web_returns_loss,
    COALESCE(cs.catalog_sales_profit, 0) AS catalog_sales_profit,
    (COALESCE(ss.store_sales_profit, 0) - COALESCE(sr.store_returns_loss, 0)
     + COALESCE(ws.web_sales_profit, 0) - COALESCE(wr.web_returns_loss, 0)
     + COALESCE(cs.catalog_sales_profit, 0)) AS total_net_profit
FROM store_sales_by_state ss
FULL OUTER JOIN store_returns_by_state sr ON ss.state = sr.state
FULL OUTER JOIN web_sales_by_state ws ON COALESCE(ss.state, sr.state) = ws.state
FULL OUTER JOIN web_returns_by_state wr ON COALESCE(ss.state, sr.state, ws.state) = wr.state
FULL OUTER JOIN catalog_sales_by_state cs ON COALESCE(ss.state, sr.state, ws.state, wr.state) = cs.state
ORDER BY total_net_profit DESC
LIMIT 25
