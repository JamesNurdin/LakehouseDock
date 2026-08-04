WITH
  sold_items AS (
    SELECT DISTINCT ss_item_sk FROM store_sales
  ),
  returned_items AS (
    SELECT DISTINCT sr_item_sk FROM store_returns
  ),
  non_returned_items AS (
    SELECT ss_item_sk FROM sold_items
    EXCEPT
    SELECT sr_item_sk FROM returned_items
  ),
  inv_wh AS (
    SELECT inv.*, w.w_warehouse_name
    FROM (SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)) inv
    FULL OUTER JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  ),
  base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_addr_sk,
      ss.ss_store_sk,
      ss.ss_promo_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_sales_price,
      i.i_category,
      i.i_brand,
      t.t_hour,
      d.cd_gender,
      hd.hd_income_band_sk,
      s.s_store_name,
      p.p_promo_name,
      wwh.w_warehouse_name,
      r.r_reason_desc,
      cr.cr_return_amount,
      sr.sr_return_amt,
      ws.ws_net_paid,
      (ss.ss_quantity * ss.ss_sales_price) AS sales_amount
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics d ON ss.ss_cdemo_sk = d.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = ss.ss_item_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_time_sk = ss.ss_sold_time_sk AND ws.ws_item_sk = ss.ss_item_sk
    LEFT JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
    LEFT JOIN inv_wh wwh ON wwh.inv_item_sk = ss.ss_item_sk
    WHERE ss.ss_item_sk IN (SELECT ss_item_sk FROM non_returned_items)
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451053
      AND i.i_current_price > 100
      AND t.t_hour BETWEEN 9 AND 17
  )
SELECT
  i_category AS category,
  i_brand AS brand,
  SUM(sales_amount) AS total_sales,
  COUNT(DISTINCT s_store_name) AS distinct_stores,
  AVG(sales_amount) AS avg_sales_per_transaction,
  COUNT(DISTINCT ss_item_sk) FILTER (WHERE sales_amount > 0) AS distinct_items_sold
FROM base
GROUP BY i_category, i_brand
HAVING SUM(sales_amount) > 10000
ORDER BY total_sales DESC
LIMIT 100
