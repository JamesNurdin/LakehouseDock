WITH
  sales_agg AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_sold_date_sk,
      SUM(cs.cs_net_paid) AS total_sales,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    GROUP BY GROUPING SETS (
      (cs.cs_item_sk, cs.cs_sold_date_sk),
      (cs.cs_item_sk),
      (cs.cs_sold_date_sk)
    )
  ),
  returns_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      SUM(cr.cr_return_amount) AS total_returns,
      COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    GROUP BY GROUPING SETS (
      (cr.cr_item_sk, cr.cr_returned_date_sk),
      (cr.cr_item_sk),
      (cr.cr_returned_date_sk)
    )
  ),
  store_sales_agg AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      SUM(ss.ss_net_paid) AS total_store_sales,
      COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
  ),
  common_orders AS (
    SELECT cs_order_number AS order_number
    FROM catalog_sales
    INTERSECT
    SELECT cr_order_number
    FROM catalog_returns
  )
SELECT *
FROM (
  SELECT
    d.d_year,
    i.i_category,
    p.p_promo_name,
    sm.sm_type,
    s.s_store_name,
    t.t_hour,
    sales_agg.total_sales,
    returns_agg.total_returns,
    store_sales_agg.total_store_sales,
    ROW_NUMBER() OVER (PARTITION BY d.d_year, i.i_category ORDER BY sales_agg.total_sales DESC) AS rank
  FROM common_orders co
  JOIN catalog_sales cs ON cs.cs_order_number = co.order_number
  JOIN catalog_returns cr ON cr.cr_order_number = co.order_number
  JOIN sales_agg ON sales_agg.cs_item_sk = cs.cs_item_sk
                 AND sales_agg.cs_sold_date_sk = cs.cs_sold_date_sk
  JOIN returns_agg ON returns_agg.cr_item_sk = cr.cr_item_sk
                    AND returns_agg.cr_returned_date_sk = cr.cr_returned_date_sk
  JOIN store_sales ss ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
  JOIN store_sales_agg ON store_sales_agg.ss_store_sk = ss.ss_store_sk
                        AND store_sales_agg.ss_sold_date_sk = ss.ss_sold_date_sk
  JOIN store s ON s.s_store_sk = ss.ss_store_sk
  JOIN date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
  JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
  JOIN time_dim t ON t.t_time_sk = cs.cs_sold_time_sk
  JOIN item i ON i.i_item_sk = cs.cs_item_sk
  JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
  JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
  WHERE d.d_year = 2001
    AND i.i_manufact_id IN (220, 460)
    AND p.p_channel_radio = 'N'
    AND s.s_state = 'CA'
    AND d_closed.d_year = 2000
    AND sales_agg.total_sales > 10000
) q
WHERE q.rank <= 5
ORDER BY q.d_year, q.i_category, q.rank
LIMIT 100
