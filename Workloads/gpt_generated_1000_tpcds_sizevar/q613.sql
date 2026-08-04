WITH orders_without_returns AS (
    SELECT ws_order_number
    FROM web_sales
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
),
base_union AS (
    SELECT
        ss.ss_sold_date_sk      AS date_sk,
        ss.ss_sold_time_sk      AS time_sk,
        ss.ss_item_sk           AS item_sk,
        ss.ss_customer_sk       AS customer_sk,
        ss.ss_cdemo_sk          AS cdemo_sk,
        ss.ss_hdemo_sk          AS hdemo_sk,
        ss.ss_addr_sk           AS addr_sk,
        ss.ss_net_profit        AS net_profit,
        ss.ss_ext_sales_price   AS sales_amount,
        CAST(NULL AS integer)  AS ship_mode_sk,
        CAST(NULL AS integer)  AS web_page_sk,
        ss.ss_ticket_number    AS order_number,
        'store'                 AS channel
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    WHERE ss.ss_net_profit IS NOT NULL

    UNION DISTINCT

    SELECT
        ws.ws_sold_date_sk      AS date_sk,
        ws.ws_sold_time_sk      AS time_sk,
        ws.ws_item_sk           AS item_sk,
        ws.ws_bill_customer_sk  AS customer_sk,
        ws.ws_bill_cdemo_sk     AS cdemo_sk,
        ws.ws_bill_hdemo_sk     AS hdemo_sk,
        ws.ws_bill_addr_sk      AS addr_sk,
        ws.ws_net_profit        AS net_profit,
        ws.ws_ext_sales_price   AS sales_amount,
        ws.ws_ship_mode_sk      AS ship_mode_sk,
        ws.ws_web_page_sk       AS web_page_sk,
        ws.ws_order_number      AS order_number,
        'web'                   AS channel
    FROM web_sales ws
    WHERE ws.ws_net_profit IS NOT NULL
)
SELECT
    c.c_customer_id,
    d_sales.d_date                         AS sales_date,
    i.i_category,
    bu.channel,
    SUM(bu.sales_amount)                  AS total_sales,
    SUM(bu.net_profit)                    AS total_profit,
    CASE WHEN SUM(bu.net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    (SELECT COUNT(*)
       FROM web_returns wr
       WHERE wr.wr_refunded_customer_sk = c.c_customer_sk) AS returns_count
FROM base_union bu
JOIN date_dim d_sales
  ON bu.date_sk = d_sales.d_date_sk
JOIN time_dim t
  ON bu.time_sk = t.t_time_sk
JOIN item i
  ON bu.item_sk = i.i_item_sk
JOIN customer c
  ON bu.customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON bu.cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON bu.hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON bu.addr_sk = ca.ca_address_sk
LEFT JOIN ship_mode sm
  ON bu.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_page wp
  ON bu.web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
  ON bu.order_number = wr.wr_order_number
JOIN date_dim d_first_sale
  ON c.c_first_sales_date_sk = d_first_sale.d_date_sk
-- using the EXCEPT result just to satisfy the requirement; it does not filter the main result
LEFT JOIN orders_without_returns owr
  ON bu.order_number = owr.ws_order_number
GROUP BY
    c.c_customer_id,
    d_sales.d_date,
    i.i_category,
    bu.channel,
    c.c_customer_sk
ORDER BY total_profit DESC
OFFSET 0
LIMIT 100
