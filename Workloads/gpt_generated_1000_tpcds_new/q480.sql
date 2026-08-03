WITH
  /* 1️⃣ Store‑sales focused data */
  sales_store AS (
    SELECT
      d.d_date,
      d.d_date_sk,
      s.s_store_id,
      s.s_state,
      ss.ss_quantity,
      ss.ss_net_profit,
      ss.ss_ext_sales_price,
      CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_profit DESC) AS rn_store_profit
    FROM
      date_dim d
      JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
      JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
      JOIN store s ON ss.ss_store_sk = s.s_store_sk
      JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
      JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
      AND s.s_state = 'CA'
      AND ss.ss_quantity > 1
      AND inv.inv_quantity_on_hand > 0
      AND ss.ss_ext_sales_price > 1000
  ),

  /* 2️⃣ Web‑sales focused data */
  web_data AS (
    SELECT
      d.d_date,
      d.d_date_sk,
      wsite.web_site_id,
      ws.ws_quantity,
      ws.ws_net_profit,
      ws.ws_ext_sales_price,
      CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
      ROW_NUMBER() OVER (PARTITION BY wsite.web_site_id ORDER BY ws.ws_net_profit DESC) AS rn_site_profit
    FROM
      date_dim d
      JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
      JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
      JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
      JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
      JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
      JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
      d.d_year = 2001
      AND wsite.web_tax_percentage > 5
      AND ws.ws_quantity > 2
      AND ws.ws_sales_price > 100
  ),

  /* 3️⃣ Key set subtraction (store ids that never appear as a web‑site id) */
  store_ids AS (SELECT s_store_id FROM sales_store),
  web_ids   AS (SELECT web_site_id FROM web_data),
  diff_ids  AS (
    SELECT s_store_id FROM store_ids
    EXCEPT
    SELECT web_site_id FROM web_ids
  ),

  /* 4️⃣ Join the two analytical streams, keep all rows (FULL OUTER) and only keep store rows that have a matching catalog return */
  combined AS (
    SELECT
      COALESCE(ss.s_store_id, wd.web_site_id)      AS entity_id,
      COALESCE(ss.profit_flag, wd.profit_flag)    AS profit_flag,
      ss.rn_store_profit,
      wd.rn_site_profit,
      ss.d_date
    FROM
      sales_store ss
      FULL OUTER JOIN web_data wd ON ss.d_date = wd.d_date
    WHERE
      EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_returned_date_sk = ss.d_date_sk
      )
  )
SELECT
  entity_id,
  profit_flag,
  rn_store_profit,
  rn_site_profit,
  d_date
FROM combined
ORDER BY profit_flag DESC, entity_id
LIMIT 100
