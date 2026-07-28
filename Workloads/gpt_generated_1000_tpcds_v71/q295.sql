WITH base AS (
    SELECT
        d.d_year AS year,
        ss.ss_store_sk AS store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(COALESCE(cr.cr_fee, 0)) AS total_return_fee,
        MAX(ws.web_name) AS web_name
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
           AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
           AND cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
           AND cr.cr_item_sk = cs.cs_item_sk
           AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ss.ss_ext_tax > 50
      AND (cr.cr_fee > 20 OR cr.cr_fee IS NULL)
    GROUP BY d.d_year, ss.ss_store_sk
)
SELECT
    year,
    store_sk,
    total_store_profit,
    total_return_fee,
    web_name,
    RANK() OVER (PARTITION BY year ORDER BY total_store_profit DESC) AS profit_rank
FROM base
ORDER BY year, profit_rank
LIMIT 100
