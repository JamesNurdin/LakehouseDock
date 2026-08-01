WITH
  sales_agg AS (
    SELECT
      s.s_store_id AS store_id,
      d.d_year,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
      SUM(DISTINCT ss.ss_ext_sales_price) AS distinct_sales,
      COUNT(DISTINCT i.i_brand_id) AS distinct_brands,
      SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
      AND d.d_current_quarter = 'Y'
      AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_date_sk = d.d_date_sk
          AND inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY s.s_store_id, d.d_year
  ),
  returns_agg AS (
    SELECT
      w.web_site_id AS web_site_id,
      d.d_year,
      COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
      SUM(DISTINCT wr.wr_return_amt) AS distinct_return_amount,
      COUNT(DISTINCT i.i_category_id) AS distinct_categories,
      SUM(wr.wr_net_loss) AS total_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
      AND d.d_holiday = 'N'
      AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_date_sk = d.d_date_sk
          AND inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY w.web_site_id, d.d_year
  ),
  union_set AS (
    SELECT
      store_id AS location_id,
      d_year,
      distinct_tickets AS metric_a,
      distinct_sales AS metric_b,
      distinct_brands AS metric_c,
      total_profit AS metric_d,
      'store' AS source
    FROM sales_agg
    UNION
    SELECT
      web_site_id AS location_id,
      d_year,
      distinct_orders AS metric_a,
      distinct_return_amount AS metric_b,
      distinct_categories AS metric_c,
      total_loss AS metric_d,
      'web' AS source
    FROM returns_agg
  ),
  exclude_set AS (
    SELECT
      s.s_store_id AS location_id,
      d.d_year,
      COUNT(DISTINCT ss.ss_ticket_number) AS metric_a,
      SUM(DISTINCT ss.ss_ext_sales_price) AS metric_b,
      COUNT(DISTINCT i.i_brand_id) AS metric_c,
      SUM(ss.ss_net_profit) AS metric_d,
      'store' AS source
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
      AND ss.ss_net_paid < 0
      AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_date_sk = d.d_date_sk
          AND inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY s.s_store_id, d.d_year
  )
SELECT
  location_id,
  d_year,
  metric_a,
  metric_b,
  metric_c,
  metric_d,
  source
FROM union_set
EXCEPT
SELECT
  location_id,
  d_year,
  metric_a,
  metric_b,
  metric_c,
  metric_d,
  source
FROM exclude_set
ORDER BY metric_d DESC
LIMIT 100
