WITH
  sales_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(ss.ss_net_paid)        AS metric,
      COUNT(DISTINCT ss.ss_ticket_number) AS cnt,
      'sales'                     AS src
    FROM store_sales ss
    JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i            ON ss.ss_item_sk = i.i_item_sk
    JOIN store s           ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p       ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND p.p_promo_name LIKE '%Clearance%'
      AND s.s_state = 'CA'
      AND i.i_brand = 'BrandX'
      AND hd.hd_income_band_sk = 5
    GROUP BY d.d_year, i.i_category
  ),

  returns_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(cr.cr_net_loss)          AS metric,
      COUNT(DISTINCT cr.cr_order_number) AS cnt,
      'catalog_returns'            AS src
    FROM catalog_returns cr
    JOIN date_dim d          ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i              ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_sales cs    ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r            ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%damaged%'
      AND cr.cr_return_quantity > 0
      AND cr.cr_fee > 0
    GROUP BY d.d_year, i.i_category
  ),

  web_returns_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(wr.wr_net_loss)          AS metric,
      COUNT(*)                     AS cnt,
      'web_returns'                AS src
    FROM web_returns wr
    JOIN date_dim d        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i            ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r          ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
    GROUP BY d.d_year, i.i_category
  ),

  store_returns_agg AS (
    SELECT
      d.d_year,
      i.i_category,
      SUM(sr.sr_net_loss)          AS metric,
      COUNT(*)                     AS cnt,
      'store_returns'              AS src
    FROM store_returns sr
    JOIN date_dim d        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i            ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r          ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s           ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND r.r_reason_id = 'AAAAAAAJAAAAAAA'
    GROUP BY d.d_year, i.i_category
  ),

  combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
    UNION ALL
    SELECT * FROM store_returns_agg
  )
SELECT
  c.d_year,
  c.i_category,
  SUM(CASE WHEN c.src = 'sales'          THEN c.metric ELSE 0 END) AS sum_sales_net_paid,
  SUM(CASE WHEN c.src = 'catalog_returns' THEN c.metric ELSE 0 END) AS sum_catalog_returns_net_loss,
  SUM(CASE WHEN c.src = 'web_returns'    THEN c.metric ELSE 0 END) AS sum_web_returns_net_loss,
  SUM(CASE WHEN c.src = 'store_returns'  THEN c.metric ELSE 0 END) AS sum_store_returns_net_loss,
  SUM(c.cnt)                                              AS total_count,
  (SELECT COUNT(*) FROM customer)                        AS total_customers
FROM combined c
WHERE EXISTS (
        SELECT 1
        FROM store s2
        JOIN store_sales ss2 ON s2.s_store_sk = ss2.ss_store_sk
        WHERE s2.s_state = 'CA'
          AND ss2.ss_ticket_number = (
                SELECT MAX(ss3.ss_ticket_number)
                FROM store_sales ss3
                WHERE ss3.ss_sold_date_sk = (
                      SELECT d2.d_date_sk
                      FROM date_dim d2
                      WHERE d2.d_year = 2001
                      LIMIT 1
                )
          )
      )
  AND EXISTS (
        SELECT 1
        FROM web_site ws
        JOIN date_dim d3 ON ws.web_open_date_sk = d3.d_date_sk
        WHERE d3.d_year = 2001
          AND ws.web_country = 'USA'
      )
GROUP BY c.d_year, c.i_category
ORDER BY c.d_year DESC, sum_sales_net_paid DESC
LIMIT 100
