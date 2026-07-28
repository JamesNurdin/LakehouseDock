WITH
  -- Aggregate catalog sales per customer for the target year
  cust_sales AS (
    SELECT
      c.c_customer_sk,
      d_year.d_year,
      SUM(cs.cs_net_profit)               AS catalog_net_profit,
      SUM(cs.cs_ext_sales_price)          AS catalog_sales_amount
    FROM customer c
    JOIN date_dim d_year
      ON c.c_first_sales_date_sk = d_year.d_date_sk
    JOIN catalog_sales cs
      ON cs.cs_bill_customer_sk = c.c_customer_sk
     AND cs.cs_sold_date_sk     = d_year.d_date_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d_year.d_year = 2001
      AND i.i_current_price > 50
      AND cs.cs_quantity > 5
      AND p.p_discount_active = 'Y'
    GROUP BY c.c_customer_sk, d_year.d_year
  ),
  -- Aggregate web sales per customer for the target year
  web_sales_agg AS (
    SELECT
      c.c_customer_sk,
      d_year.d_year,
      SUM(ws.ws_net_profit)          AS web_net_profit,
      SUM(ws.ws_ext_sales_price)     AS web_sales_amount
    FROM customer c
    JOIN date_dim d_year
      ON c.c_first_sales_date_sk = d_year.d_date_sk
    JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_sold_date_sk     = d_year.d_date_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site webs
      ON ws.ws_web_site_sk = webs.web_site_sk
    WHERE d_year.d_year = 2001
      AND i.i_current_price > 50
      AND ws.ws_quantity > 3
      AND p.p_discount_active = 'Y'
    GROUP BY c.c_customer_sk, d_year.d_year
  ),
  -- Aggregate catalog returns per customer for the target year (join reason for table usage)
  catalog_ret_agg AS (
    SELECT
      cr.cr_refunded_customer_sk AS cust_sk,
      d_ret.d_year,
      SUM(cr.cr_return_amount)   AS catalog_return_amount
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d_ret.d_year = 2001
    GROUP BY cr.cr_refunded_customer_sk, d_ret.d_year
  ),
  -- Aggregate store returns per customer for the target year (join store for table usage)
  store_ret_agg AS (
    SELECT
      sr.sr_customer_sk AS cust_sk,
      d_ret.d_year,
      SUM(sr.sr_return_amt) AS store_return_amount
    FROM store_returns sr
    JOIN date_dim d_ret
      ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
     AND s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
    GROUP BY sr.sr_customer_sk, d_ret.d_year
  ),
  -- Aggregate web returns per customer for the target year (join reason for table usage)
  web_ret_agg AS (
    SELECT
      wr.wr_refunded_customer_sk AS cust_sk,
      d_ret.d_year,
      SUM(wr.wr_return_amt) AS web_return_amount
    FROM web_returns wr
    JOIN date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r2
      ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE d_ret.d_year = 2001
    GROUP BY wr.wr_refunded_customer_sk, d_ret.d_year
  )
SELECT
  c.c_customer_id,
  d.d_year,
  COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)               AS total_net_profit,
  COALESCE(cs.catalog_sales_amount, 0) + COALESCE(ws.web_sales_amount, 0)           AS total_sales_amount,
  COALESCE(cr.catalog_return_amount, 0) + COALESCE(sr.store_return_amount, 0) + COALESCE(wr.web_return_amount, 0) AS total_return_amount,
  RANK() OVER (PARTITION BY d.d_year ORDER BY (COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)) DESC) AS profit_rank
FROM customer c
JOIN date_dim d
  ON c.c_first_sales_date_sk = d.d_date_sk
LEFT JOIN cust_sales cs
  ON cs.c_customer_sk = c.c_customer_sk AND cs.d_year = d.d_year
LEFT JOIN web_sales_agg ws
  ON ws.c_customer_sk = c.c_customer_sk AND ws.d_year = d.d_year
LEFT JOIN catalog_ret_agg cr
  ON cr.cust_sk = c.c_customer_sk AND cr.d_year = d.d_year
LEFT JOIN store_ret_agg sr
  ON sr.cust_sk = c.c_customer_sk AND sr.d_year = d.d_year
LEFT JOIN web_ret_agg wr
  ON wr.cust_sk = c.c_customer_sk AND wr.d_year = d.d_year
WHERE d.d_year = 2001
  -- Customer must have at least one web sale (semi‑join via EXISTS)
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
          AND ws2.ws_sold_date_sk = d.d_date_sk
      )
  -- Exclude customers who ever had a store return on the same year (anti‑join via NOT EXISTS)
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_returned_date_sk = d.d_date_sk
      )
ORDER BY profit_rank
LIMIT 100
