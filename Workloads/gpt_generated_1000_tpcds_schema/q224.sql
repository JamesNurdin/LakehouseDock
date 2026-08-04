WITH
  -- Sampled web sales as the central fact table
  sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_ship_date_sk,
      ws.ws_item_sk,
      ws.ws_web_page_sk,
      ws.ws_web_site_sk,
      ws.ws_ship_mode_sk,
      ws.ws_promo_sk,
      ws.ws_net_profit,
      ws.ws_ext_sales_price,
      ws.ws_quantity,
      i.i_category,
      i.i_brand,
      i.i_item_id,
      i.i_product_name,
      p.p_promo_name,
      sm.sm_type AS ship_mode_type,
      wp.wp_type AS page_type,
      wsite.web_name,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM web_sales ws
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i          ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p     ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp     ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite  ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d_sold.d_year = 2001                     -- filter 1
      AND i.i_brand = 'Brand#12'                   -- filter 2
      AND p.p_discount_active = 'Y'               -- filter 3
      AND ws.ws_net_profit IS NOT NULL            -- filter 4
  ),

  -- Web returns for the same orders (to be used in EXCEPT and reason lookup)
  returns AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_quantity,
      r.r_reason_desc
    FROM web_returns wr
    JOIN reason r               ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_sales ws           ON wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_return_quantity > 0
  ),

  -- Orders that appear in sales but not in returns (EXCEPT usage)
  order_excl AS (
    SELECT ws_order_number FROM sales
    EXCEPT
    SELECT wr_order_number FROM returns
  ),

  -- Catalog pages linked through their start date
  catalog AS (
    SELECT
      cp.cp_catalog_page_id,
      cp.cp_department,
      cp.cp_catalog_number,
      d.d_date_sk
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE cp.cp_department = 'DEPARTMENT'
  ),

  -- Stores closed on a given date (joined through the closed‑date surrogate key)
  stores AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_tax_percentage,
      d.d_date_sk
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_tax_percentage > 0
  ),

  -- Aggregate store‑sales per store (joined later via store surrogate key)
  store_sales_agg AS (
    SELECT
      ss.ss_store_sk,
      SUM(ss.ss_net_paid) AS store_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk
  )

SELECT
  s.ws_order_number,
  d_sold.d_date,
  s.i_item_id,
  s.i_product_name,
  s.p_promo_name,
  s.ship_mode_type,
  s.page_type,
  s.web_name,
  s.profit_flag,
  s.ws_net_profit,
  RANK() OVER (PARTITION BY s.i_category ORDER BY s.ws_net_profit DESC) AS category_profit_rank,
  CASE WHEN s.ws_net_profit > 1000 THEN 'High' ELSE 'Medium' END AS profit_level,
  cp.cp_catalog_page_id,
  st.s_store_name,
  ss.store_net_paid,
  r.r_reason_desc
FROM sales s
JOIN date_dim d_sold ON s.ws_sold_date_sk = d_sold.d_date_sk
LEFT JOIN catalog cp      ON d_sold.d_date_sk = cp.d_date_sk
LEFT JOIN stores st       ON d_sold.d_date_sk = st.d_date_sk
LEFT JOIN store_sales_agg ss ON ss.ss_store_sk = st.s_store_sk
LEFT JOIN returns r       ON s.ws_order_number = r.wr_order_number
INNER JOIN order_excl oe   ON s.ws_order_number = oe.ws_order_number
ORDER BY s.ws_net_profit DESC, s.ws_order_number
LIMIT 100
