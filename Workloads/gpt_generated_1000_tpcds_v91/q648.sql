WITH store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_addr_sk AS addr_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(ss.ss_net_profit) AS store_profit_total,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_ext_sales_price ELSE 0 END) AS store_positive_sales
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
      AND ss.ss_sales_price > 0
      AND ss.ss_ext_sales_price IS NOT NULL
      AND ss.ss_net_profit IS NOT NULL
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_promo_sk, ss.ss_customer_sk, ss.ss_addr_sk
),

web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_bill_addr_sk AS addr_sk,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        SUM(ws.ws_net_profit) AS web_profit_total,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
        SUM(CASE WHEN ws.ws_net_profit > 0 THEN ws.ws_ext_sales_price ELSE 0 END) AS web_positive_sales
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
      AND ws.ws_sales_price > 0
      AND ws.ws_ext_sales_price IS NOT NULL
      AND ws.ws_net_profit IS NOT NULL
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_promo_sk, ws.ws_bill_customer_sk, ws.ws_bill_addr_sk
),

customers_without_returns AS (
    SELECT DISTINCT ss.customer_sk
    FROM store_sales_agg ss
    EXCEPT
    SELECT DISTINCT cr.cr_refunded_customer_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
)

SELECT
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    c.c_customer_id,
    ca.ca_city,
    ss.store_sales_total,
    ws.web_sales_total,
    (ss.store_sales_total + ws.web_sales_total) AS total_sales,
    CASE
        WHEN (ss.store_sales_total + ws.web_sales_total) > 10000 THEN 'HIGH'
        WHEN (ss.store_sales_total + ws.web_sales_total) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_category,
    ROUND((ss.store_profit_total + ws.web_profit_total) / NULLIF((ss.store_sales_total + ws.web_sales_total), 0), 4) AS profit_margin
FROM store_sales_agg ss
JOIN web_sales_agg ws
  ON ss.date_sk = ws.date_sk
  AND ss.item_sk = ws.item_sk
  AND ss.promo_sk = ws.promo_sk
JOIN date_dim d
  ON ss.date_sk = d.d_date_sk
JOIN item i
  ON ss.item_sk = i.i_item_sk
JOIN promotion p
  ON ss.promo_sk = p.p_promo_sk
JOIN customer c
  ON ss.customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON ss.addr_sk = ca.ca_address_sk
JOIN customers_without_returns cuwr
  ON ss.customer_sk = cuwr.customer_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
  AND cr.cr_item_sk = i.i_item_sk
  AND cr.cr_refunded_customer_sk = c.c_customer_sk
  AND cr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE d.d_year = 1998
  AND d.d_weekend = 'N'
  AND i.i_color = 'Blue'
  AND p.p_channel_email = 'N'
  AND p.p_purpose = 'Unknown'
  AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
LIMIT 100
