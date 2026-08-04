WITH
  sales AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_customer_sk,
      ss.ss_item_sk,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      d_sales.d_year,
      i.i_category,
      ca.ca_state,
      p.p_discount_active
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2001
      AND i.i_category = 'Sports'
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND ss.ss_ticket_number NOT IN (SELECT wr.wr_order_number FROM web_returns wr)
  ),
  returns AS (
    SELECT
      wr.wr_order_number,
      d_ret.d_year,
      i.i_category,
      wr.wr_return_amt,
      wr.wr_net_loss,
      ca.ca_zip
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d_ret.d_date_sk
    JOIN web_site ws ON ws.web_close_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND ca.ca_zip = '75124'
      AND i.i_brand = 'Brand#23'
  ),
  customer_diff AS (
    SELECT ss_customer_sk FROM sales
    EXCEPT
    SELECT wr_returning_customer_sk FROM web_returns
  )
SELECT
  agg.year,
  agg.category,
  SUM(agg.sales_amount) AS total_sales,
  SUM(agg.returns_amount) AS total_returns,
  COUNT(DISTINCT agg.customer_sk) AS distinct_customers,
  AVG(agg.profit) AS avg_profit
FROM (
  SELECT
    d_year AS year,
    i_category AS category,
    ss_ext_sales_price AS sales_amount,
    0.0 AS returns_amount,
    ss_customer_sk AS customer_sk,
    ss_net_profit AS profit
  FROM sales
  UNION DISTINCT
  SELECT
    d_year AS year,
    i_category AS category,
    0.0 AS sales_amount,
    wr_return_amt AS returns_amount,
    NULL AS customer_sk,
    -wr_net_loss AS profit
  FROM returns
) agg
WHERE agg.customer_sk IS NULL OR agg.customer_sk IN (SELECT ss_customer_sk FROM customer_diff)
GROUP BY agg.year, agg.category
ORDER BY total_sales DESC
OFFSET 0 LIMIT 10
