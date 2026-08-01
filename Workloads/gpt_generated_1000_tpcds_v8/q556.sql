WITH
  intersect_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    INTERSECT
    SELECT ws.ws_order_number AS order_number
    FROM web_sales ws
  ),

  sales_union AS (
    SELECT
      ws.ws_order_number                               AS order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_ext_sales_price                           AS sales_amount,
      ws.ws_coupon_amt,
      ws.ws_net_profit,
      p.p_promo_name,
      ca.ca_state,
      hd.hd_buy_potential,
      CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
      regexp_extract(p.p_promo_name, '([0-9]{2})', 1)  AS promo_digits,
      (
        SELECT SUM(wr.wr_return_amt)
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
      )                                               AS total_return_amt
    FROM web_sales ws
    JOIN promotion p               ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca       ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_order_number IN (SELECT order_number FROM intersect_orders)
      AND regexp_like(p.p_promo_name, '^.*[0-9]{2}.*$')
      AND ca.ca_state LIKE 'A%'

    UNION DISTINCT

    SELECT
      cs.cs_order_number                               AS order_number,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_ext_sales_price                           AS sales_amount,
      cs.cs_coupon_amt,
      cs.cs_net_profit,
      p.p_promo_name,
      ca.ca_state,
      hd.hd_buy_potential,
      CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
      regexp_extract(p.p_promo_name, '([0-9]{2})', 1)  AS promo_digits,
      (
        SELECT SUM(wr.wr_return_amt)
        FROM web_returns wr
        WHERE wr.wr_order_number = cs.cs_order_number
      )                                               AS total_return_amt
    FROM catalog_sales cs
    JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_order_number IN (SELECT order_number FROM intersect_orders)
      AND regexp_like(p.p_promo_name, '^.*[0-9]{2}.*$')
      AND ca.ca_state LIKE 'A%'
  )

SELECT
  su.p_promo_name,
  su.ca_state,
  su.hd_buy_potential,
  su.profit_flag,
  su.promo_digits,
  CONCAT(su.p_promo_name, ' - ', su.ca_state) AS promo_state,
  COUNT(DISTINCT su.order_number)                 AS order_cnt,
  SUM(su.sales_amount)                           AS total_sales,
  SUM(su.total_return_amt)                       AS total_returns,
  SUM(su.sales_amount) - SUM(su.total_return_amt) AS net_sales
FROM sales_union su
GROUP BY CUBE (
  su.p_promo_name,
  su.ca_state,
  su.hd_buy_potential,
  su.profit_flag,
  su.promo_digits
)
ORDER BY total_sales DESC
LIMIT 100
