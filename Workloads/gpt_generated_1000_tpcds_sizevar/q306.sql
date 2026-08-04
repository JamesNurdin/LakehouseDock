WITH
  -- scalar subquery used later for a comparison
  max_active_promo_cost AS (
    SELECT MAX(p.p_cost) AS max_cost
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
  ),
  -- turn the comma‑separated channel list into an array and unnest it
  promo_channels AS (
    SELECT p.p_promo_sk,
           SPLIT(p.p_channel_details, ',') AS channel_arr
    FROM promotion p
    WHERE p.p_channel_details IS NOT NULL
  ),
  expanded_channels AS (
    SELECT pc.p_promo_sk,
           TRIM(ch) AS channel
    FROM promo_channels pc
    CROSS JOIN UNNEST(pc.channel_arr) AS t(ch)
  ),
  -- the main star‑join using date_dim as the hub
  joined_all AS (
    SELECT
      d.d_date_sk,
      d.d_year,
      d.d_month_seq,
      t.t_time_sk,
      t.t_hour,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      cd.cd_demo_sk,
      cd.cd_gender,
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      w.w_warehouse_sk,
      w.w_warehouse_name,
      inv.inv_quantity_on_hand,
      cp.cp_catalog_page_sk,
      cp.cp_department,
      cs.cs_quantity AS cs_quantity,
      cs.cs_net_paid AS cs_net_paid,
      ss.ss_quantity AS ss_quantity,
      ss.ss_net_paid AS ss_paid,
      ws.ws_sales_price,
      ws.ws_quantity,
      wr.wr_return_quantity,
      wr.wr_net_loss,
      we.web_name,
      p.p_promo_sk,
      p.p_promo_id,
      ec.channel
    FROM date_dim d
    LEFT JOIN time_dim t ON t.t_time_sk = d.d_date_sk   -- allowed via rule on time_dim (no direct rule, but we keep the join optional; it will be filtered out later)
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_site we ON we.web_open_date_sk = d.d_date_sk OR we.web_close_date_sk = d.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk OR cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk OR w.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk OR p.p_promo_sk = ss.ss_promo_sk OR p.p_promo_sk = ws.ws_promo_sk
    LEFT JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk OR c.c_customer_sk = ss.ss_customer_sk OR c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk OR cd.cd_demo_sk = ss.ss_cdemo_sk OR cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    LEFT JOIN expanded_channels ec ON ec.p_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'TX'
      AND (cs.cs_quantity > 5 OR ss.ss_quantity > 5 OR ws.ws_quantity > 5)
      AND cs.cs_net_paid > (SELECT max_cost FROM max_active_promo_cost)
  )
SELECT
  j.d_year,
  j.s_store_name,
  j.p_promo_id,
  j.channel,
  SUM(j.cs_quantity + j.ss_quantity + j.ws_quantity) AS total_qty,
  AVG(j.cs_net_paid + j.ss_paid + j.ws_sales_price) AS avg_revenue,
  COUNT(DISTINCT j.c_customer_sk) AS distinct_customers,
  MIN(j.inv_quantity_on_hand) AS min_inventory,
  MAX(j.ws_sales_price) AS max_ws_price
FROM joined_all j
GROUP BY
  j.d_year,
  j.s_store_name,
  j.p_promo_id,
  j.channel
HAVING SUM(j.cs_quantity + j.ss_quantity + j.ws_quantity) > 100
EXCEPT
SELECT
  d_year,
  s_store_name,
  p_promo_id,
  channel,
  total_qty,
  avg_revenue,
  distinct_customers,
  min_inventory,
  max_ws_price
FROM (
  SELECT
    d.d_year AS d_year,
    s.s_store_name AS s_store_name,
    p.p_promo_id AS p_promo_id,
    NULL AS channel,
    SUM(cs.cs_quantity) AS total_qty,
    AVG(cs.cs_net_paid) AS avg_revenue,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    MIN(inv.inv_quantity_on_hand) AS min_inventory,
    MAX(ws.ws_sales_price) AS max_ws_price
  FROM date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN store s ON s.s_store_sk = cs.cs_ship_customer_sk
  JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
  LEFT JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
  LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
  LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, s.s_store_name, p.p_promo_id
) t
LIMIT 100
