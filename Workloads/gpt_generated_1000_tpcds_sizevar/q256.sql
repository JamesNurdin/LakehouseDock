WITH cs_sample AS (
    SELECT cs_order_number,
           cs_item_sk,
           cs_bill_cdemo_sk,
           cs_bill_addr_sk,
           cs_promo_sk,
           cs_quantity,
           cs_sales_price,
           cs_net_profit
    FROM catalog_sales TABLESAMPLE BERNOULLI (5)
    WHERE cs_quantity > 5
      AND cs_sales_price > 100
),
ws_filtered AS (
    SELECT ws_order_number,
           ws_item_sk,
           ws_bill_cdemo_sk,
           ws_bill_addr_sk,
           ws_promo_sk,
           ws_quantity,
           ws_sales_price,
           ws_net_profit
    FROM web_sales
    WHERE ws_quantity > 3
),
excluded_orders AS (
    SELECT cs_order_number
    FROM cs_sample
    EXCEPT
    SELECT ws_order_number
    FROM ws_filtered
)
SELECT
    d.d_year,
    s.s_store_name,
    i1.i_category,
    COUNT(DISTINCT cs.cs_order_number)                     AS catalog_order_cnt,
    SUM(cs.cs_net_profit)                                 AS catalog_net_profit,
    COUNT(DISTINCT ws.ws_order_number)                    AS web_order_cnt,
    SUM(ws.ws_net_profit)                                 AS web_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number)                  AS store_sales_cnt,
    SUM(ss.ss_net_profit)                                 AS store_net_profit,
    COUNT(DISTINCT sr.sr_ticket_number)                  AS store_return_cnt,
    SUM(sr.sr_net_loss)                                   AS store_return_loss
FROM date_dim d
LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
LEFT JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
LEFT JOIN item i1 ON i1.i_item_sk = cs.cs_item_sk
LEFT JOIN item i2 ON i2.i_item_sk = ws.ws_item_sk
LEFT JOIN item i3 ON i3.i_item_sk = ss.ss_item_sk
LEFT JOIN customer_demographics cd1 ON cd1.cd_demo_sk = cs.cs_bill_cdemo_sk
LEFT JOIN customer_demographics cd2 ON cd2.cd_demo_sk = ws.ws_bill_cdemo_sk
LEFT JOIN customer_address ca1 ON ca1.ca_address_sk = cs.cs_bill_addr_sk
LEFT JOIN customer_address ca2 ON ca2.ca_address_sk = ws.ws_bill_addr_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN web_site we ON we.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i1.i_color = 'red'
  AND ca1.ca_state = 'TX'
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_discount_active = 'Y'
    )
  AND cs.cs_order_number IN (SELECT cs_order_number FROM excluded_orders)
GROUP BY d.d_year, s.s_store_name, i1.i_category
ORDER BY catalog_net_profit DESC
LIMIT 100
