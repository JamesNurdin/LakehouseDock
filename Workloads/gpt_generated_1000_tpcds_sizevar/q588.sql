WITH
  sampled_sales AS (
    SELECT * FROM web_sales TABLESAMPLE BERNOULLI (10)
  ),
  sales_enriched AS (
    SELECT
      ss.ws_order_number,
      ss.ws_sold_date_sk,
      d_sold.d_date          AS sale_date,
      ss.ws_ship_date_sk,
      d_ship.d_date          AS ship_date,
      ss.ws_net_profit,
      CASE WHEN ss.ws_net_profit > 100 THEN 'High' ELSE 'Low' END AS profit_category,
      ws.web_site_id,
      ws.web_name,
      ss.ws_quantity,
      ss.ws_ext_sales_price,
      ss.ws_ext_discount_amt,
      p.p_promo_name,
      p.p_discount_active,
      ROW_NUMBER() OVER (PARTITION BY ss.ws_web_site_sk ORDER BY d_sold.d_date) AS sales_seq
    FROM sampled_sales ss
    JOIN date_dim d_sold        ON ss.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship        ON ss.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer cust_bill    ON ss.ws_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer_address addr_bill ON ss.ws_bill_addr_sk = addr_bill.ca_address_sk
    JOIN promotion p           ON ss.ws_promo_sk = p.p_promo_sk
    JOIN web_site ws           ON ss.ws_web_site_sk = ws.web_site_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
  ),
  returns_enriched AS (
    SELECT
      wr.wr_order_number,
      d_ret.d_date                AS return_date,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      cust_ret.c_customer_id,
      addr_ret.ca_state,
      cp.cp_catalog_page_id,
      cp.cp_department
    FROM web_returns wr
    JOIN web_sales ws_ret         ON wr.wr_order_number = ws_ret.ws_order_number
    JOIN date_dim d_ret           ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer cust_ret        ON wr.wr_refunded_customer_sk = cust_ret.c_customer_sk
    JOIN customer_address addr_ret ON wr.wr_refunded_addr_sk = addr_ret.ca_address_sk
    JOIN catalog_page cp          ON d_ret.d_date_sk = cp.cp_end_date_sk
  ),
  intersect_orders AS (
    SELECT ws_order_number FROM sales_enriched WHERE ws_net_profit > 0
    INTERSECT
    SELECT wr_order_number FROM returns_enriched WHERE wr_return_amt > 0
  ),
  sales_only_orders AS (
    SELECT ws_order_number FROM sales_enriched
    EXCEPT
    SELECT wr_order_number FROM returns_enriched
  ),
  full_page_date AS (
    SELECT cp.cp_catalog_page_id, d_full.d_date AS page_date
    FROM catalog_page cp
    FULL OUTER JOIN date_dim d_full ON cp.cp_end_date_sk = d_full.d_date_sk
  ),
  final_set AS (
    SELECT
      s.ws_order_number,
      s.sale_date,
      s.ship_date,
      s.ws_net_profit,
      s.profit_category,
      s.web_site_id,
      s.web_name,
      s.sales_seq,
      CASE WHEN r.wr_order_number IS NOT NULL THEN 1 ELSE 0 END AS has_return,
      SUM(s.ws_ext_sales_price) OVER (
        PARTITION BY s.web_site_id
        ORDER BY s.sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS running_sales
    FROM sales_enriched s
    LEFT JOIN returns_enriched r ON s.ws_order_number = r.wr_order_number
    WHERE s.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
  )
SELECT *
FROM final_set
ORDER BY sale_date DESC, web_site_id
LIMIT 100
