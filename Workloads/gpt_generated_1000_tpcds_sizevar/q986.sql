WITH
  sampled_items AS (
    SELECT *
    FROM item TABLESAMPLE BERNOULLI (10)
  ),

  sales_agg AS (
    SELECT
      ws_item_sk,
      ws_sold_date_sk,
      ws_bill_cdemo_sk,
      ws_bill_hdemo_sk,
      ws_bill_addr_sk,
      ws_promo_sk,
      ws_web_page_sk,
      ws_web_site_sk,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_quantity) AS total_qty
    FROM web_sales
    WHERE ws_ext_sales_price > 1000
      AND ws_quantity > 0
      AND ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    GROUP BY ws_item_sk, ws_sold_date_sk, ws_bill_cdemo_sk, ws_bill_hdemo_sk,
             ws_bill_addr_sk, ws_promo_sk, ws_web_page_sk, ws_web_site_sk
  ),

  returns_agg AS (
    SELECT
      wr_item_sk,
      wr_returned_date_sk,
      wr_reason_sk,
      SUM(wr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_return_amt > 0
      AND wr_return_quantity > 0
      AND wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    GROUP BY wr_item_sk, wr_returned_date_sk, wr_reason_sk
  ),

  sales_returns_full AS (
    SELECT
      COALESCE(s.ws_item_sk, r.wr_item_sk) AS item_sk,
      COALESCE(s.ws_sold_date_sk, r.wr_returned_date_sk) AS date_sk,
      s.total_sales,
      r.total_return_amt,
      s.total_qty,
      r.return_cnt,
      s.ws_bill_cdemo_sk,
      s.ws_bill_hdemo_sk,
      s.ws_bill_addr_sk,
      s.ws_promo_sk,
      s.ws_web_page_sk,
      s.ws_web_site_sk,
      r.wr_reason_sk
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
      ON s.ws_item_sk = r.wr_item_sk
     AND s.ws_sold_date_sk = r.wr_returned_date_sk
  ),

  order_numbers_sales AS (
    SELECT ws_order_number AS order_no
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
  ),

  order_numbers_returns AS (
    SELECT wr_order_number AS order_no
    FROM web_returns
    WHERE wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
  ),

  orders_only_in_sales AS (
    SELECT order_no FROM order_numbers_sales
    EXCEPT
    SELECT order_no FROM order_numbers_returns
  ),

  orders_in_both AS (
    SELECT order_no FROM order_numbers_sales
    INTERSECT
    SELECT order_no FROM order_numbers_returns
  ),

  final_data AS (
    SELECT
      sr.item_sk,
      i.i_product_name,
      d.d_date,
      sr.total_sales,
      sr.total_return_amt,
      sr.total_qty,
      sr.return_cnt,
      cd.cd_gender,
      hd.hd_buy_potential,
      ca.ca_city,
      p.p_promo_name,
      wp.wp_type,
      ws.web_name,
      r.r_reason_desc,
      ROW_NUMBER() OVER (PARTITION BY sr.item_sk ORDER BY sr.total_sales DESC NULLS LAST) AS sales_rank,
      CASE
        WHEN sr.total_sales IS NULL THEN 'Return Only'
        WHEN sr.total_return_amt IS NULL THEN 'Sale Only'
        ELSE 'Both'
      END AS sales_return_flag
    FROM sales_returns_full sr
    LEFT JOIN sampled_items i      ON sr.item_sk = i.i_item_sk
    LEFT JOIN date_dim d            ON sr.date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd ON sr.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON sr.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca   ON sr.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN promotion p           ON sr.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp           ON sr.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws           ON sr.ws_web_site_sk = ws.web_site_sk
    LEFT JOIN reason r              ON sr.wr_reason_sk = r.r_reason_sk
    WHERE sr.total_sales > 5000
      AND (sr.total_return_amt IS NULL OR sr.total_return_amt < 2000)
      AND d.d_moy IN (1, 5, 10)
      AND i.i_brand IS NOT NULL
  )
SELECT *
FROM final_data
WHERE sales_return_flag <> 'Return Only'
ORDER BY total_sales DESC, sales_rank
LIMIT 100
