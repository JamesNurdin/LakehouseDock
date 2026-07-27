WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ss_net_profit) AS total_store_profit
    FROM store_sales
    GROUP BY ss_item_sk, ss_sold_date_sk
),
ws_agg AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(ws_net_profit) AS total_web_profit
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk
),
base_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_addr_sk,
        ss_store_sk,
        ss_ticket_number,
        ss_ext_sales_price,
        ss_net_profit
    FROM store_sales
)
SELECT DISTINCT
    d.d_date,
    d.d_year,
    i.i_item_id,
    i.i_category,
    s.s_store_id,
    s.s_state,
    c.c_customer_id,
    ca.ca_city,
    agg.total_store_sales,
    agg.total_store_profit,
    wagg.total_web_sales,
    wagg.total_web_profit,
    COALESCE(cr.cr_return_amount, 0) AS catalog_return_amount,
    COALESCE(wr.wr_return_amt, 0) AS web_return_amount,
    COALESCE(sr.sr_return_amt, 0) AS store_return_amount,
    (
        agg.total_store_profit +
        wagg.total_web_profit -
        COALESCE(cr.cr_return_amount, 0) -
        COALESCE(wr.wr_return_amt, 0) -
        COALESCE(sr.sr_return_amt, 0)
    ) AS net_profit_adj,
    RANK() OVER (
        PARTITION BY d.d_year
        ORDER BY (
            agg.total_store_profit +
            wagg.total_web_profit -
            COALESCE(cr.cr_return_amount, 0) -
            COALESCE(wr.wr_return_amt, 0) -
            COALESCE(sr.sr_return_amt, 0)
        ) DESC
    ) AS profit_rank
FROM base_sales ss
JOIN ss_agg agg
    ON ss.ss_item_sk = agg.ss_item_sk
   AND ss.ss_sold_date_sk = agg.ss_sold_date_sk
LEFT JOIN ws_agg wagg
    ON ss.ss_item_sk = wagg.ws_item_sk
   AND ss.ss_sold_date_sk = wagg.ws_sold_date_sk
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
LEFT JOIN catalog_returns cr
    ON ss.ss_item_sk = cr.cr_item_sk
   AND ss.ss_sold_date_sk = cr.cr_returned_date_sk
LEFT JOIN web_sales ws
    ON ss.ss_item_sk = ws.ws_item_sk
   AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND i.i_category = 'Electronics'
  AND s.s_state = 'CA'
  AND ws.ws_net_profit > 0
LIMIT 100
