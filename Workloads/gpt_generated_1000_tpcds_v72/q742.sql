WITH
  sales_a AS (
    SELECT
      i.i_item_id                                 AS item_id,
      i.i_product_name                           AS product_name,
      cp.cp_catalog_number                       AS catalog_number,
      wp.wp_url                                  AS page_url,
      p.p_promo_name                             AS promo_name,
      t.t_hour                                   AS hour_of_day,
      SUM(
        COALESCE(ss.ss_ext_sales_price, 0) +
        COALESCE(cs.cs_ext_sales_price, 0) +
        COALESCE(ws.ws_ext_sales_price, 0)
      )                                          AS total_sales,
      SUM(COALESCE(sr.sr_return_amt, 0))         AS total_returns,
      COUNT(DISTINCT ss.ss_ticket_number)        AS sales_txns,
      COUNT(DISTINCT sr.sr_ticket_number)        AS return_txns,
      CASE WHEN SUM(COALESCE(sr.sr_return_amt, 0)) > 0
           THEN 'Has Returns'
           ELSE 'No Returns' END                AS return_flag
    FROM
      item i
      LEFT JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
      LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
      LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
      LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
      LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
      LEFT JOIN promotion p
        ON p.p_promo_sk = COALESCE(ss.ss_promo_sk, cs.cs_promo_sk, ws.ws_promo_sk)
      LEFT JOIN time_dim t
        ON t.t_time_sk = COALESCE(ss.ss_sold_time_sk, cs.cs_sold_time_sk, ws.ws_sold_time_sk)
      LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
      LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
      LEFT JOIN customer c
        ON c.c_customer_sk = ss.ss_customer_sk
      LEFT JOIN customer_address ca
        ON ca.ca_address_sk = ss.ss_addr_sk
      LEFT JOIN customer_demographics cd
        ON cd.cd_demo_sk = ss.ss_cdemo_sk
      LEFT JOIN household_demographics hd
        ON hd.hd_demo_sk = ss.ss_hdemo_sk
    WHERE
      i.i_current_price BETWEEN 10 AND 200
      AND t.t_hour >= 9
      AND p.p_discount_active = 'Y'
      AND ca.ca_state IS NOT NULL
    GROUP BY
      GROUPING SETS (
        (i.i_item_id, i.i_product_name, cp.cp_catalog_number, wp.wp_url, p.p_promo_name, t.t_hour),
        (i.i_item_id, i.i_product_name, cp.cp_catalog_number, wp.wp_url, p.p_promo_name),
        (i.i_item_id, i.i_product_name)
      )
  ),

  sales_b AS (
    SELECT
      i.i_item_id                                 AS item_id,
      i.i_product_name                           AS product_name,
      cp.cp_catalog_number                       AS catalog_number,
      wp.wp_url                                  AS page_url,
      p.p_promo_name                             AS promo_name,
      t.t_hour                                   AS hour_of_day,
      SUM(
        COALESCE(ss.ss_ext_sales_price, 0) +
        COALESCE(cs.cs_ext_sales_price, 0) +
        COALESCE(ws.ws_ext_sales_price, 0)
      )                                          AS total_sales,
      SUM(COALESCE(sr.sr_return_amt, 0))         AS total_returns,
      COUNT(DISTINCT ss.ss_ticket_number)        AS sales_txns,
      COUNT(DISTINCT sr.sr_ticket_number)        AS return_txns,
      CASE WHEN SUM(COALESCE(sr.sr_return_amt, 0)) > 0
           THEN 'Has Returns'
           ELSE 'No Returns' END                AS return_flag
    FROM
      item i
      LEFT JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
      LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
      LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
      LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
      LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
      LEFT JOIN promotion p
        ON p.p_promo_sk = COALESCE(ss.ss_promo_sk, cs.cs_promo_sk, ws.ws_promo_sk)
      LEFT JOIN time_dim t
        ON t.t_time_sk = COALESCE(ss.ss_sold_time_sk, cs.cs_sold_time_sk, ws.ws_sold_time_sk)
      LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
      LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
      LEFT JOIN customer c
        ON c.c_customer_sk = ss.ss_customer_sk
      LEFT JOIN customer_address ca
        ON ca.ca_address_sk = ss.ss_addr_sk
      LEFT JOIN customer_demographics cd
        ON cd.cd_demo_sk = ss.ss_cdemo_sk
      LEFT JOIN household_demographics hd
        ON hd.hd_demo_sk = ss.ss_hdemo_sk
    WHERE
      i.i_current_price > 150
      AND t.t_hour <= 12
      AND p.p_discount_active = 'N'
      AND ca.ca_country = 'USA'
    GROUP BY
      GROUPING SETS (
        (i.i_item_id, i.i_product_name, cp.cp_catalog_number, wp.wp_url, p.p_promo_name, t.t_hour),
        (i.i_item_id, i.i_product_name, cp.cp_catalog_number, wp.wp_url, p.p_promo_name),
        (i.i_item_id, i.i_product_name)
      )
  ),

  combined AS (
    SELECT * FROM sales_a
    UNION ALL
    SELECT * FROM sales_b
  )

SELECT
  item_id,
  product_name,
  catalog_number,
  page_url,
  promo_name,
  hour_of_day,
  total_sales,
  total_returns,
  sales_txns,
  return_txns,
  return_flag,
  SUM(total_sales) OVER (PARTITION BY promo_name ORDER BY hour_of_day
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_promo,
  ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY total_sales DESC) AS sales_rank,
  DENSE_RANK() OVER (ORDER BY total_sales DESC) AS overall_rank
FROM combined
ORDER BY total_sales DESC
LIMIT 100
