WITH
  filtered_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_category = 'Sports'
  ),
  all_joins AS (
    SELECT
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_profit,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_promo_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      d_sold.d_year           AS year,
      t_sold.t_hour           AS hour,
      i.i_brand,
      p.p_promo_name          AS promotion_name,
      cc.cc_name              AS call_center_name,
      cp.cp_department,
      s.s_store_name          AS store_name,
      inv.inv_quantity_on_hand,
      ws.web_name             AS web_site_name,
      wp.wp_url
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_store
      ON cc.cc_closed_date_sk = d_store.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ws
      ON s.s_closed_date_sk = d_ws.d_date_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d_ws.d_date_sk
    JOIN date_dim d_wp
      ON ws.web_open_date_sk = d_wp.d_date_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d_wp.d_date_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN date_dim d_return
      ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return
      ON cr.cr_returned_time_sk = t_return.t_time_sk
    WHERE cs.cs_item_sk IN (SELECT i_item_sk FROM filtered_items)
      AND d_sold.d_date_sk = (
        SELECT MAX(d_date_sk)
        FROM date_dim
        WHERE d_year = 2001
      )
  )
SELECT
  store_name,
  year,
  promotion_name,
  SUM(total_quantity) AS total_quantity,
  SUM(total_profit)   AS total_profit
FROM (
  SELECT
    store_name,
    year,
    promotion_name,
    cs_quantity    AS total_quantity,
    cs_net_profit  AS total_profit
  FROM all_joins
  WHERE year = 2001

  UNION DISTINCT

  SELECT
    store_name,
    year,
    promotion_name,
    cs_quantity    AS total_quantity,
    cs_net_profit  AS total_profit
  FROM all_joins
  WHERE year = 2000
) AS unioned
GROUP BY
  store_name,
  year,
  promotion_name
ORDER BY
  total_profit DESC
LIMIT 100
