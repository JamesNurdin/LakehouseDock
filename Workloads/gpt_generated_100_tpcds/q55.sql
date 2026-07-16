WITH
    states AS (
        SELECT DISTINCT ca_state
        FROM customer_address
    ),
    store_profit AS (
        SELECT
            ca_state,
            SUM(ss_net_profit) AS store_net_profit
        FROM store_sales
        JOIN customer ON store_sales.ss_customer_sk = customer.c_customer_sk
        JOIN customer_address ON store_sales.ss_addr_sk = customer_address.ca_address_sk
        GROUP BY ca_state
    ),
    catalog_profit AS (
        SELECT
            ca_state,
            SUM(cs_net_profit) AS catalog_net_profit
        FROM catalog_sales
        JOIN customer ON catalog_sales.cs_bill_customer_sk = customer.c_customer_sk
        JOIN customer_address ON catalog_sales.cs_bill_addr_sk = customer_address.ca_address_sk
        GROUP BY ca_state
    ),
    web_profit AS (
        SELECT
            ca_state,
            SUM(ws_net_profit) AS web_net_profit
        FROM web_sales
        JOIN customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
        JOIN customer_address ON web_sales.ws_bill_addr_sk = customer_address.ca_address_sk
        GROUP BY ca_state
    ),
    web_returns_loss AS (
        SELECT
            ca_state,
            SUM(wr_net_loss) AS returns_net_loss
        FROM web_returns
        JOIN customer_address ON web_returns.wr_refunded_addr_sk = customer_address.ca_address_sk
        GROUP BY ca_state
    )
SELECT
    s.ca_state,
    COALESCE(sp.store_net_profit, 0)      AS store_net_profit,
    COALESCE(cp.catalog_net_profit, 0)    AS catalog_net_profit,
    COALESCE(wp.web_net_profit, 0)       AS web_net_profit,
    COALESCE(wr.returns_net_loss, 0)     AS returns_net_loss,
    COALESCE(sp.store_net_profit, 0) + COALESCE(cp.catalog_net_profit, 0) + COALESCE(wp.web_net_profit, 0) - COALESCE(wr.returns_net_loss, 0) AS total_net_profit
FROM states s
LEFT JOIN store_profit   sp ON s.ca_state = sp.ca_state
LEFT JOIN catalog_profit cp ON s.ca_state = cp.ca_state
LEFT JOIN web_profit     wp ON s.ca_state = wp.ca_state
LEFT JOIN web_returns_loss wr ON s.ca_state = wr.ca_state
ORDER BY total_net_profit DESC
LIMIT 20
