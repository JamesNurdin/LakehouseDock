WITH store_sales_state AS (
    SELECT
        ca_state,
        ss_net_paid,
        ss_net_profit
    FROM store_sales
    JOIN customer_address
        ON store_sales.ss_addr_sk = customer_address.ca_address_sk
),
store_returns_state AS (
    SELECT
        ca_state,
        sr_refunded_cash,
        sr_net_loss
    FROM store_returns
    JOIN customer_address
        ON store_returns.sr_addr_sk = customer_address.ca_address_sk
),
catalog_sales_state AS (
    SELECT
        ca_state,
        cs_net_paid,
        cs_net_profit
    FROM catalog_sales
    JOIN customer_address
        ON catalog_sales.cs_bill_addr_sk = customer_address.ca_address_sk
),
catalog_returns_state AS (
    SELECT
        ca_state,
        cr_refunded_cash,
        cr_net_loss
    FROM catalog_returns
    JOIN customer_address
        ON catalog_returns.cr_refunded_addr_sk = customer_address.ca_address_sk
),
web_sales_state AS (
    SELECT
        ca_state,
        ws_net_paid,
        ws_net_profit
    FROM web_sales
    JOIN customer_address
        ON web_sales.ws_bill_addr_sk = customer_address.ca_address_sk
),
web_returns_state AS (
    SELECT
        ca_state,
        wr_refunded_cash,
        wr_net_loss
    FROM web_returns
    JOIN customer_address
        ON web_returns.wr_refunded_addr_sk = customer_address.ca_address_sk
),
combined AS (
    SELECT 'store_sales' AS channel,
           ca_state,
           ss_net_paid AS net_amount,
           ss_net_profit AS net_profit_or_loss
    FROM store_sales_state
    UNION ALL
    SELECT 'store_returns' AS channel,
           ca_state,
           -sr_refunded_cash AS net_amount,
           -sr_net_loss AS net_profit_or_loss
    FROM store_returns_state
    UNION ALL
    SELECT 'catalog_sales' AS channel,
           ca_state,
           cs_net_paid AS net_amount,
           cs_net_profit AS net_profit_or_loss
    FROM catalog_sales_state
    UNION ALL
    SELECT 'catalog_returns' AS channel,
           ca_state,
           -cr_refunded_cash AS net_amount,
           -cr_net_loss AS net_profit_or_loss
    FROM catalog_returns_state
    UNION ALL
    SELECT 'web_sales' AS channel,
           ca_state,
           ws_net_paid AS net_amount,
           ws_net_profit AS net_profit_or_loss
    FROM web_sales_state
    UNION ALL
    SELECT 'web_returns' AS channel,
           ca_state,
           -wr_refunded_cash AS net_amount,
           -wr_net_loss AS net_profit_or_loss
    FROM web_returns_state
),
aggregated AS (
    SELECT channel,
           ca_state,
           sum(net_amount) AS total_net_amount,
           sum(net_profit_or_loss) AS total_net_profit_or_loss
    FROM combined
    GROUP BY channel, ca_state
)
SELECT channel,
       ca_state,
       total_net_amount,
       total_net_profit_or_loss,
       row_number() OVER (PARTITION BY channel ORDER BY total_net_amount DESC) AS state_rank_by_amount
FROM aggregated
ORDER BY channel, total_net_amount DESC
LIMIT 200
