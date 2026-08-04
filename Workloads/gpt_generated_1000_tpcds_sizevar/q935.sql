WITH
  sales AS (
    SELECT
      i.i_item_sk,
      d.d_year,
      SUM(cs.cs_ext_sales_price) AS sales_amount,
      SUM(cs.cs_quantity) AS sales_qty
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_discount_active = 'Y'
      AND cp.cp_department = 'Electronics'
    GROUP BY GROUPING SETS ((i.i_item_sk, d.d_year), (i.i_item_sk), (d.d_year))
    HAVING SUM(cs.cs_ext_sales_price) > 1000
  ),
  returns AS (
    SELECT
      i.i_item_sk,
      d.d_year,
      SUM(sr.sr_return_amt) AS return_amount,
      SUM(sr.sr_return_quantity) AS return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_return_quantity > 0
    GROUP BY GROUPING SETS ((i.i_item_sk, d.d_year), (i.i_item_sk), (d.d_year))
    HAVING SUM(sr.sr_return_amt) < 5000
  ),
  web AS (
    SELECT
      i.i_item_sk,
      d.d_year,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount,
      SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE wp.wp_link_count > 5
      AND wsite.web_country = 'United States'
    GROUP BY GROUPING SETS ((i.i_item_sk, d.d_year), (i.i_item_sk), (d.d_year))
    HAVING SUM(ws.ws_ext_sales_price) > 2000
  ),
  common_keys AS (
    SELECT i_item_sk, d_year FROM (
      SELECT i.i_item_sk, d.d_year
      FROM catalog_sales cs
      JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
    )
    INTERSECT
    SELECT i_item_sk, d_year FROM (
      SELECT i.i_item_sk, d.d_year
      FROM store_returns sr
      JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
      JOIN item i ON sr.sr_item_sk = i.i_item_sk
    )
  ),
  combined AS (
    SELECT
      ck.i_item_sk,
      ck.d_year,
      COALESCE(s.sales_amount, 0) AS sales_amount,
      COALESCE(r.return_amount, 0) AS return_amount,
      COALESCE(w.web_sales_amount, 0) AS web_sales_amount,
      (COALESCE(s.sales_amount, 0) - COALESCE(r.return_amount, 0) + COALESCE(w.web_sales_amount, 0)) AS net_amount
    FROM common_keys ck
    LEFT JOIN sales s ON s.i_item_sk = ck.i_item_sk AND s.d_year = ck.d_year
    LEFT JOIN returns r ON r.i_item_sk = ck.i_item_sk AND r.d_year = ck.d_year
    LEFT JOIN web w ON w.i_item_sk = ck.i_item_sk AND w.d_year = ck.d_year
    WHERE ck.d_year BETWEEN 1998 AND 2000
      AND COALESCE(s.sales_amount, 0) > 5000
      AND COALESCE(r.return_amount, 0) < 3000
  )
SELECT
  d_year,
  i_item_sk,
  sales_amount,
  return_amount,
  web_sales_amount,
  net_amount,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_amount DESC) AS rank_in_year
FROM combined
WHERE net_amount > 0
ORDER BY d_year ASC, net_amount DESC
LIMIT 100
