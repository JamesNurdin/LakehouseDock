WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_profit,
        sr.sr_returned_date_sk,
        sr.sr_refunded_cash,
        sr.sr_store_credit,
        sr.sr_net_loss,
        inv.inv_quantity_on_hand,
        inv.inv_warehouse_sk,
        d_sales.d_year,
        d_sales.d_date,
        c.c_customer_sk,
        c.c_birth_country,
        ca.ca_state,
        ws.web_site_id,
        ws.web_name,
        ws.web_state,
        ws.web_gmt_offset
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sales.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    WHERE d_sales.d_year = 2000
      AND c.c_birth_country = 'SWITZERLAND'
      AND inv.inv_quantity_on_hand > 1000
      AND ws.web_gmt_offset = -5.00
),
expanded AS (
    SELECT
        b.*, 
        CASE WHEN b.inv_quantity_on_hand >= 5000 THEN 'High Stock' ELSE 'Low Stock' END AS inventory_category,
        w.word AS web_name_word
    FROM base b
    CROSS JOIN UNNEST(split(b.web_name, ' ')) AS w(word)
),
aggregated AS (
    SELECT
        d_year,
        c_birth_country,
        web_state,
        inventory_category,
        web_name_word,
        SUM(ss_net_profit) AS total_net_profit,
        AVG(ss_net_profit) AS avg_net_profit,
        COUNT(*) AS transaction_count,
        SUM(CASE WHEN sr_refunded_cash > 100 THEN sr_refunded_cash ELSE 0 END) AS total_refunded_cash,
        MAX(ss_net_profit) AS max_net_profit,
        MIN(ss_net_profit) AS min_net_profit
    FROM expanded
    GROUP BY ROLLUP (d_year, c_birth_country, web_state, inventory_category, web_name_word)
)
SELECT
    d_year,
    c_birth_country,
    web_state,
    inventory_category,
    web_name_word,
    total_net_profit,
    avg_net_profit,
    transaction_count,
    total_refunded_cash,
    max_net_profit,
    min_net_profit,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY d_year ASC,
         c_birth_country ASC,
         web_state ASC,
         inventory_category ASC,
         total_net_profit DESC
