/*
  Goal: Identify the top-selling items (by net sales) that have been sold but not returned, 
  showing sales, returns, promotion cost, and profitability indicators, while exercising a variety 
  of advanced SQL features (multiple joins, table reuse via aliases, FULL OUTER JOIN, EXCEPT, 
  LATERAL subquery, CASE expressions, HAVING with a scalar subquery, and ordering with LIMIT).
*/
WITH
  /* Base sales data – joins sales to item, promotion, address and demographics */
  ss_base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_sales_price,
      ss.ss_ext_sales_price,
      ss.ss_net_paid,
      ss.ss_net_profit,
      i.i_item_id,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      ca.ca_state,
      cd.cd_gender,
      CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  ),

  /* Base returns data – joins returns to item, web page, address and demographics (different aliases) */
  wr_base AS (
    SELECT
      wr.wr_order_number,
      wr.wr_item_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_net_loss,
      i.i_item_id,
      i.i_category,
      i.i_brand,
      wp.wp_max_ad_count,
      ca.ca_state      AS return_state,
      cd.cd_gender    AS return_gender
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  ),

  /* Lateral subquery: average promotion cost for the item sold */
  ss_with_lateral AS (
    SELECT
      sb.*,
      lag_promo.avg_promo_cost
    FROM ss_base sb
    LEFT JOIN LATERAL (
      SELECT avg(p.p_cost) AS avg_promo_cost
      FROM promotion p
      WHERE p.p_item_sk = sb.ss_item_sk
    ) lag_promo ON TRUE
  ),

  /* Full outer join between the sales side and the returns side – keeps unmatched rows from both */
  full_sales_returns AS (
    SELECT
      COALESCE(s.i_item_id, r.i_item_id)         AS item_id,
      s.i_category,
      s.i_brand,
      s.ss_ext_sales_price,
      r.wr_return_amt,
      s.profit_flag,
      r.wp_max_ad_count,
      s.avg_promo_cost,
      r.return_state
    FROM ss_with_lateral s
    FULL OUTER JOIN wr_base r ON s.ss_item_sk = r.wr_item_sk
  ),

  /* Sets of items sold and items returned */
  sold_items AS (
    SELECT DISTINCT i_item_id FROM ss_base
  ),
  returned_items AS (
    SELECT DISTINCT i_item_id FROM wr_base
  ),

  /* Items that were sold but never returned – using EXCEPT */
  items_sold_not_returned AS (
    SELECT i_item_id FROM sold_items
    EXCEPT
    SELECT i_item_id FROM returned_items
  ),

  /* Aggregate metrics per item */
  final_agg AS (
    SELECT
      f.item_id,
      f.i_category,
      f.i_brand,
      SUM(COALESCE(f.ss_ext_sales_price, 0))               AS total_sales,
      SUM(COALESCE(f.wr_return_amt, 0))                     AS total_returns,
      SUM(COALESCE(f.ss_ext_sales_price, 0) - COALESCE(f.wr_return_amt, 0)) AS net_amount,
      AVG(f.avg_promo_cost)                                 AS avg_promo_cost,
      COUNT(DISTINCT f.profit_flag) FILTER (WHERE f.profit_flag = 'Profitable') AS profitable_sales_cnt,
      MAX(f.wp_max_ad_count)                               AS max_ad_count
    FROM full_sales_returns f
    GROUP BY f.item_id, f.i_category, f.i_brand
    HAVING SUM(COALESCE(f.ss_ext_sales_price, 0)) > (
      SELECT avg_sales FROM (
        SELECT avg(ss_ext_sales_price) AS avg_sales FROM ss_base
      ) t
    )
  )

SELECT
  fa.item_id,
  fa.i_category,
  fa.i_brand,
  fa.total_sales,
  fa.total_returns,
  fa.net_amount,
  fa.avg_promo_cost,
  fa.profitable_sales_cnt,
  fa.max_ad_count,
  CASE WHEN fa.net_amount > 0 THEN 'Net Positive' ELSE 'Net Negative' END AS net_status
FROM final_agg fa
WHERE fa.item_id IN (SELECT i_item_id FROM items_sold_not_returned)
ORDER BY fa.total_sales DESC
LIMIT 100
