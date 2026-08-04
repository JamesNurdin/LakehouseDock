WITH
  /* Join all selected tables using only the allowed keys */
  base AS (
    SELECT
      d.d_year,
      i.i_category,
      i.i_item_sk,
      ss.ss_ext_sales_price,
      ws.ws_ext_sales_price,
      cs.cs_ext_sales_price,
      cs.cs_promo_sk,
      ws.ws_promo_sk,
      sr.sr_return_amt,
      wr.wr_return_amt,
      inv.inv_quantity_on_hand,
      cc.cc_name,
      cp.cp_catalog_page_number,
      sm.sm_type          AS cs_ship_mode_type,
      sm_ws.sm_type       AS ws_ship_mode_type,
      r.r_reason_desc,
      ca.ca_state,
      wsite.web_site_sk
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t1
      ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_sales cs
      ON cs.cs_item_sk = i.i_item_sk
     AND cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_brand_id = 12
      AND ca.ca_state IN ('CA','TX','NY')
  ),

  /* Expand an array (promo keys) with UNNEST */
  promo_exp AS (
    SELECT
      b.d_year,
      b.i_category,
      ARRAY[ b.cs_promo_sk, b.ws_promo_sk ] AS promo_keys,
      COALESCE(b.cs_ext_sales_price,0) + COALESCE(b.ws_ext_sales_price,0) AS total_sales
    FROM base b
  ),

  unpivoted AS (
    SELECT
      d_year,
      i_category,
      promo_key,
      total_sales
    FROM promo_exp
    CROSS JOIN UNNEST(promo_keys) AS t(promo_key)
  ),

  /* Aggregation with GROUP BY CUBE and CASE expression */
  agg_sales AS (
    SELECT
      d_year,
      i_category,
      SUM(total_sales)                       AS sum_sales,
      COUNT(*)                               AS cnt_sales,
      CASE WHEN SUM(total_sales) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM unpivoted
    GROUP BY CUBE(d_year, i_category)
  ),

  agg_returns AS (
    SELECT
      d_year,
      i_category,
      SUM(sr_return_amt)                    AS sum_returns,
      COUNT(*)                               AS cnt_returns,
      CASE WHEN SUM(sr_return_amt) > 50000 THEN 'HighReturn' ELSE 'LowReturn' END AS return_level
    FROM base
    GROUP BY CUBE(d_year, i_category)
  ),

  /* Full outer join of the two aggregates */
  joined_agg AS (
    SELECT
      a1.d_year,
      a1.i_category,
      a1.sum_sales,
      a2.sum_returns,
      a1.sales_level,
      a2.return_level
    FROM agg_sales a1
    FULL OUTER JOIN agg_returns a2
      ON a1.d_year = a2.d_year AND a1.i_category = a2.i_category
  ),

  /* Second SELECT for UNION – keep rows that have only return info */
  only_returns AS (
    SELECT
      a1.d_year,
      a1.i_category,
      a1.sum_sales,
      a2.sum_returns,
      a1.sales_level,
      a2.return_level
    FROM agg_sales a1
    FULL OUTER JOIN agg_returns a2
      ON a1.d_year = a2.d_year AND a1.i_category = a2.i_category
    WHERE a1.sum_sales IS NULL
  )

SELECT *
FROM (
  SELECT * FROM joined_agg
  UNION DISTINCT
  SELECT * FROM only_returns
) AS final_result
ORDER BY d_year DESC, i_category, sum_sales DESC
OFFSET 0
LIMIT 100
