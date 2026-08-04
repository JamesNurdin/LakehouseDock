WITH joined AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_ship_date_sk,
    cs.cs_bill_customer_sk,
    cs.cs_ship_mode_sk,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_ext_sales_price,
    cs.cs_ext_discount_amt,
    c.c_customer_sk,
    c.c_first_name,
    ca.ca_country,
    d.d_year,
    sm.sm_type,
    wr.wr_return_ship_cost,
    ws.web_name
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
  LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  WHERE c.c_first_name = 'Andre'
    AND ca.ca_country = 'United States'
    AND d.d_year = 2001
    AND (wr.wr_return_ship_cost > 500 OR wr.wr_return_ship_cost IS NULL)
),
aggregated AS (
  SELECT
    c_customer_sk,
    c_first_name,
    sm_type,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_quantity) AS avg_quantity,
    COUNT(*) AS order_count,
    CASE WHEN SUM(cs_ext_discount_amt) > 1000 THEN 'High Discount' ELSE 'Low Discount' END AS discount_level,
    (SELECT AVG(cs2.cs_ext_sales_price)
       FROM catalog_sales cs2
      WHERE cs2.cs_sold_date_sk = 2449800) AS avg_price_reference,
    (SELECT SUM(wr3.wr_return_amt)
       FROM web_returns wr3
      WHERE wr3.wr_refunded_customer_sk = c_customer_sk) AS total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY SUM(cs_net_paid) DESC) AS rn
  FROM joined
  GROUP BY c_customer_sk, c_first_name, sm_type
),
filtered AS (
  SELECT *
  FROM aggregated
  WHERE total_net_paid > (
          SELECT MIN(cs4.cs_net_paid)
            FROM catalog_sales cs4
           WHERE cs4.cs_sold_date_sk = 2449756)
    AND rn <= 3
)
SELECT
  c_customer_sk,
  c_first_name,
  sm_type,
  total_net_paid,
  avg_quantity,
  order_count,
  discount_level,
  avg_price_reference,
  total_return_amount
FROM filtered
ORDER BY total_net_paid DESC
LIMIT 100
