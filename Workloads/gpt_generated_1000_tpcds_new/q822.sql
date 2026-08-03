-- Goal: analyze total store sales (sampled) and web sales per customer by date, include catalog page and household demographics, compute prior‑day sales lag, filter for high‑value customers, and deduplicate via UNION.
WITH
  ss_agg AS (
    SELECT
      ss_sold_date_sk,
      ss_customer_sk,
      SUM(ss_ext_sales_price)   AS total_sales,
      SUM(ss_net_profit)        AS total_profit,
      COUNT(*)                  AS sales_cnt
    FROM store_sales
      TABLESAMPLE BERNOULLI (10)   -- sample 10 % of rows
    GROUP BY ss_sold_date_sk, ss_customer_sk
  ),

  ws AS (
    SELECT
      ws_bill_customer_sk,
      ws_sold_date_sk,
      ws_ext_sales_price,
      ws_net_profit,
      ws_quantity
    FROM web_sales
    WHERE ws_ext_sales_price > 1000
  ),

  base AS (
    SELECT
      c.c_customer_sk,
      d_sales.d_date,
      ss_agg.total_sales,
      ss_agg.total_profit,
      ss_agg.sales_cnt,
      cp_start.cp_catalog_page_id,
      hd_cust.hd_buy_potential
    FROM ss_agg
      FULL OUTER JOIN store_returns sr
        ON ss_agg.ss_customer_sk = sr.sr_customer_sk                                   -- join 1 (full outer)
      LEFT JOIN customer c
        ON COALESCE(ss_agg.ss_customer_sk, sr.sr_customer_sk) = c.c_customer_sk       -- join 2
      LEFT JOIN household_demographics hd_cust
        ON c.c_current_hdemo_sk = hd_cust.hd_demo_sk                                 -- join 3
      LEFT JOIN household_demographics hd_ret
        ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk                                        -- join 4
      LEFT JOIN date_dim d_sales
        ON ss_agg.ss_sold_date_sk = d_sales.d_date_sk                               -- join 5
      LEFT JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk                                 -- join 6
      LEFT JOIN catalog_page cp_start
        ON cp_start.cp_start_date_sk = d_sales.d_date_sk                            -- join 7
      LEFT JOIN catalog_page cp_end
        ON cp_end.cp_end_date_sk = d_sales.d_date_sk                                -- join 8 (second alias of catalog_page)
      LEFT JOIN ws
        ON c.c_customer_sk = ws.ws_bill_customer_sk                                 -- join 9
      LEFT JOIN date_dim d_web
        ON ws.ws_sold_date_sk = d_web.d_date_sk                                      -- join 10
    WHERE d_sales.d_year = 2001
  )

SELECT
  c_customer_sk,
  d_date,
  total_sales,
  total_profit,
  sales_cnt,
  LAG(total_sales) OVER (PARTITION BY c_customer_sk ORDER BY d_date) AS lag_total_sales,
  cp_catalog_page_id,
  hd_buy_potential
FROM base
GROUP BY
  c_customer_sk,
  d_date,
  total_sales,
  total_profit,
  sales_cnt,
  cp_catalog_page_id,
  hd_buy_potential
HAVING SUM(total_sales) > 5000

UNION DISTINCT

SELECT
  ws2.ws_bill_customer_sk   AS c_customer_sk,
  d2.d_date,
  SUM(ws2.ws_ext_sales_price) AS total_sales,
  SUM(ws2.ws_net_profit)      AS total_profit,
  COUNT(*)                    AS sales_cnt,
  CAST(NULL AS decimal(7,2)) AS lag_total_sales,
  CAST(NULL AS varchar)      AS cp_catalog_page_id,
  CAST(NULL AS varchar)      AS hd_buy_potential
FROM web_sales ws2
  JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
GROUP BY ws2.ws_bill_customer_sk, d2.d_date
HAVING SUM(ws2.ws_ext_sales_price) > 5000

LIMIT 100
