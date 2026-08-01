-- Goal: Identify top‑grossing web sales by division, gender and buying potential for customers who bought both in store and online in 2001, while demonstrating advanced SQL features (joins across all 13 tables, filters, aggregation, window ranking, UNNEST, INTERSECT, LEFT OUTER JOIN and pagination).
WITH
  -- Store‑side sales (used later for INTERSECT)
  store_sales_subset AS (
    SELECT ss_customer_sk
    FROM store_sales
    WHERE ss_quantity > 1
      AND ss_net_paid > 100
  ),

  -- Web‑side sales (used later for INTERSECT and main aggregation)
  web_sales_subset AS (
    SELECT ws_bill_customer_sk,
           ws_sold_date_sk,
           ws_sold_time_sk,
           ws_bill_cdemo_sk,
           ws_bill_hdemo_sk,
           ws_web_page_sk,
           ws_warehouse_sk,
           ws_promo_sk,
           ws_quantity,
           ws_net_paid,
           ws_order_number
    FROM web_sales
    WHERE ws_quantity > 1
      AND ws_net_paid > 100
  ),

  -- Customers that appear in both store and web sales
  common_customers AS (
    SELECT ss_customer_sk AS cust_sk FROM store_sales_subset
    INTERSECT
    SELECT ws_bill_customer_sk FROM web_sales_subset
  ),

  -- Core join that pulls in every selected table
  joined_all AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      cc.cc_division_name,
      cd.cd_gender,
      hd.hd_buy_potential,
      p.p_promo_name,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_order_number,
      ws.ws_web_page_sk,
      split(cc.cc_name, ' ') AS name_parts,
      ROW_NUMBER() OVER (PARTITION BY cc.cc_division_name ORDER BY ws.ws_net_paid DESC) AS rank_div_net_paid,
      t.t_hour,
      r.r_reason_desc,
      ws_site.web_name AS site_name,
      wp.wp_type,
      w.w_state AS warehouse_state
    FROM web_sales ws
    JOIN date_dim d               ON ws.ws_sold_date_sk   = d.d_date_sk
    JOIN time_dim t               ON ws.ws_sold_time_sk   = t.t_time_sk
    JOIN promotion p              ON ws.ws_promo_sk      = p.p_promo_sk
    LEFT JOIN web_page wp         ON ws.ws_web_page_sk   = wp.wp_web_page_sk   -- outer join requirement
    LEFT JOIN web_returns wr      ON ws.ws_order_number = wr.wr_order_number
                                   AND ws.ws_sold_date_sk = wr.wr_returned_date_sk
    LEFT JOIN reason r            ON wr.wr_reason_sk = r.r_reason_sk
    JOIN warehouse w              ON ws.ws_warehouse_sk  = w.w_warehouse_sk
    JOIN web_site ws_site          ON ws.ws_web_site_sk   = ws_site.web_site_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc           ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                                         -- filter 1
      AND d.d_month_seq BETWEEN 1 AND 12                         -- filter 2
      AND cc.cc_state = 'CA'                                      -- filter 3
      AND p.p_discount_active = 'Y'                               -- filter 4
      AND wp.wp_type = 'content'                                  -- filter 5
      AND w.w_state = 'CA'                                        -- filter 6
      AND ws.ws_bill_customer_sk IN (SELECT cust_sk FROM common_customers) -- restrict to common customers
  ),

  -- Explode the array of name parts produced by SPLIT
  exploded_names AS (
    SELECT
      ja.d_year,
      ja.d_month_seq,
      ja.cc_division_name,
      ja.cd_gender,
      ja.hd_buy_potential,
      ja.p_promo_name,
      ja.ws_quantity,
      ja.ws_net_paid,
      ja.ws_order_number,
      ja.rank_div_net_paid,
      ja.t_hour,
      ja.r_reason_desc,
      ja.site_name,
      ja.wp_type,
      ja.warehouse_state,
      name_part
    FROM joined_all ja
    CROSS JOIN UNNEST(ja.name_parts) AS t(name_part)
  )
SELECT
  d_year,
  d_month_seq,
  cc_division_name,
  cd_gender,
  hd_buy_potential,
  p_promo_name,
  COUNT(*)                         AS order_cnt,
  SUM(ws_quantity)                 AS total_quantity,
  SUM(ws_net_paid)                 AS total_net_paid,
  AVG(ws_net_paid)                 AS avg_net_paid,
  MIN(ws_net_paid)                 AS min_net_paid,
  MAX(ws_net_paid)                 AS max_net_paid,
  rank_div_net_paid,
  name_part
FROM exploded_names
GROUP BY
  d_year,
  d_month_seq,
  cc_division_name,
  cd_gender,
  hd_buy_potential,
  p_promo_name,
  rank_div_net_paid,
  name_part
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
