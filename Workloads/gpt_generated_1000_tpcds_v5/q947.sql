WITH
  store_agg AS (
    SELECT
      c.c_customer_sk,
      SUM(ss.ss_net_profit) AS profit,
      AVG(ss.ss_ext_discount_amt) AS avg_discount,
      COUNT(*) AS txn,
      0 AS distinct_warehouses
    FROM store_sales ss
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_country = 'KOREA'
      AND c.c_preferred_cust_flag = 'Y'
      AND cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_sk
  ),
  web_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS c_customer_sk,
      SUM(ws.ws_net_profit) AS profit,
      AVG(ws.ws_ext_discount_amt) AS avg_discount,
      0 AS txn,
      COUNT(DISTINCT ws.ws_warehouse_sk) AS distinct_warehouses
    FROM web_sales ws
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_char_count > 2000
    GROUP BY ws.ws_bill_customer_sk
  ),
  combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
  )
SELECT
  c.c_customer_sk,
  c.c_first_name,
  c.c_last_name,
  SUM(co.profit) AS total_profit,
  AVG(co.avg_discount) AS avg_discount,
  SUM(co.txn) AS total_transactions,
  SUM(co.distinct_warehouses) AS total_warehouses
FROM combined co
JOIN customer c
  ON co.c_customer_sk = c.c_customer_sk
WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_autogen_flag = 'N'
          AND wp.wp_char_count > 2000
      )
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
ORDER BY total_profit DESC
