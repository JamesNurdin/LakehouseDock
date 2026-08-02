WITH
  date_filtered AS (
    SELECT d.*
    FROM date_dim d
    WHERE d.d_year = 2001
  ),
  inventory_filtered AS (
    SELECT inv.*
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
      AND inv.inv_item_sk IN (
        SELECT i_item_sk
        FROM item
        WHERE i_color = 'BLACK'
      )
  ),
  store_data AS (
    SELECT
      d.d_date AS d_date,
      c.c_customer_id AS c_customer_id,
      i.i_item_id AS i_item_id,
      ss.ss_quantity AS quantity,
      ss.ss_ext_sales_price AS sales,
      ss.ss_net_profit AS profit,
      ROW_NUMBER() OVER (PARTITION BY 1 ORDER BY ss.ss_net_profit DESC) AS rank_val
    FROM date_filtered d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
                         AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN inventory_filtered inv ON inv.inv_date_sk = d.d_date_sk
                               AND inv.inv_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
                         AND cs.cs_item_sk = i.i_item_sk
                         AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE i.i_current_price > 100
      AND cs.cs_ext_sales_price > 500
      AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
          AND p.p_discount_active = 'Y'
      )
  ),
  web_data AS (
    SELECT
      d.d_date AS d_date,
      c.c_customer_id AS c_customer_id,
      i.i_item_id AS i_item_id,
      ws.ws_quantity AS quantity,
      ws.ws_ext_sales_price AS sales,
      ws.ws_net_profit AS profit,
      ROW_NUMBER() OVER (PARTITION BY 1 ORDER BY ws.ws_net_profit DESC) AS rank_val
    FROM date_filtered d
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                        AND wr.wr_item_sk = ws.ws_item_sk
                        AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
                         AND cs.cs_item_sk = i.i_item_sk
                         AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE i.i_current_price > 100
      AND cs.cs_ext_sales_price > 500
      AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ws.ws_promo_sk
          AND p.p_discount_active = 'Y'
      )
  ),
  union_data AS (
    SELECT 'Store' AS channel,
           d_date,
           c_customer_id,
           i_item_id,
           quantity,
           sales,
           profit,
           rank_val
    FROM store_data
    UNION ALL
    SELECT 'Web' AS channel,
           d_date,
           c_customer_id,
           i_item_id,
           quantity,
           sales,
           profit,
           rank_val
    FROM web_data
  )
SELECT
  u.channel,
  u.d_date,
  u.c_customer_id,
  u.i_item_id,
  u.quantity,
  u.sales,
  u.profit,
  u.rank_val,
  g.grp,
  CASE WHEN u.profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag
FROM union_data u
CROSS JOIN (
  SELECT 'X' AS grp UNION ALL SELECT 'Y' AS grp
) g
WHERE u.rank_val <= 5
ORDER BY u.channel, u.profit DESC
LIMIT 100
