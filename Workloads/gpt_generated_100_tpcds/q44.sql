WITH
store_metrics AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_cnt,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_cnt,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_amount,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_sales ss
    LEFT JOIN store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
       AND ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state, ca.ca_city
),
catalog_metrics AS (
    SELECT
        ca.ca_state,
        ca.ca_city,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_cnt,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_returns_cnt,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_item_sk = cr.cr_item_sk
       AND cs.cs_order_number = cr.cr_order_number
    LEFT JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state, ca.ca_city
)
SELECT
    COALESCE(s.ca_state, c.ca_state) AS state,
    COALESCE(s.ca_city, c.ca_city) AS city,
    s.store_sales_cnt,
    s.store_sales_amount,
    s.store_net_profit,
    s.store_returns_cnt,
    s.store_return_amount,
    s.store_net_loss,
    c.catalog_sales_cnt,
    c.catalog_sales_amount,
    c.catalog_net_paid,
    c.catalog_net_profit,
    c.catalog_returns_cnt,
    c.catalog_return_amount,
    c.catalog_net_loss
FROM store_metrics s
FULL OUTER JOIN catalog_metrics c
    ON s.ca_state = c.ca_state
   AND s.ca_city = c.ca_city
ORDER BY state, city
