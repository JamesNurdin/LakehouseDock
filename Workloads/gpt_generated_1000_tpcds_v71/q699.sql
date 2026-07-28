WITH distinct_customers AS (
  SELECT i.i_item_sk,
         COUNT(DISTINCT c.c_customer_id) AS distinct_cust_cnt
  FROM store_sales ss
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY i.i_item_sk
),
joined_data AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_item_sk,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit,
    cs.cs_order_number,
    cs.cs_list_price,
    cr.cr_return_amount,
    sr.sr_return_amt,
    wr.wr_return_amt AS web_return_amt,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    i.i_current_price,
    d.d_year,
    t.t_hour,
    ca.ca_state,
    cd.cd_gender,
    c.c_birth_year,
    inv.inv_quantity_on_hand,
    dc.distinct_cust_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
   AND cs.cs_sold_time_sk = t.t_time_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_returned_time_sk = t.t_time_sk
   AND cr.cr_order_number = cs.cs_order_number
  LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_return_time_sk = t.t_time_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
  LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
  LEFT JOIN distinct_customers dc
    ON dc.i_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND ss.ss_net_paid > 1000
    AND cs.cs_list_price BETWEEN 50 AND 200
    AND inv.inv_quantity_on_hand < 500
    AND c.c_birth_year BETWEEN 1950 AND 1960
    AND cd.cd_gender = 'M'
),
agg_data AS (
  SELECT
    i_item_id,
    i_brand,
    i_category,
    d_year,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(cs_list_price) AS sum_list_price,
    SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(sr_return_amt, 0)) AS total_store_returns,
    SUM(COALESCE(web_return_amt, 0)) AS total_web_returns,
    MIN(inv_quantity_on_hand) AS min_inventory_qty,
    MAX(distinct_cust_cnt) AS max_distinct_cust,
    AVG(i_current_price) AS avg_current_price
  FROM joined_data
  GROUP BY i_item_id, i_brand, i_category, d_year
  HAVING SUM(ss_net_paid) > 10000
)
SELECT
  i_item_id,
  i_brand,
  i_category,
  d_year,
  total_store_sales,
  total_store_profit,
  total_catalog_returns,
  total_store_returns,
  total_web_returns,
  min_inventory_qty,
  max_distinct_cust,
  avg_current_price,
  RANK() OVER (ORDER BY total_store_sales DESC) AS sales_rank,
  SUM(total_store_sales) OVER (PARTITION BY i_brand) AS brand_sales_total
FROM agg_data ad
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    JOIN item i2 ON wr2.wr_item_sk = i2.i_item_sk
    JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
    WHERE i2.i_item_id = ad.i_item_id
      AND wr2.wr_return_amt > 500
      AND d2.d_year = 2001
)
ORDER BY total_store_sales DESC
LIMIT 100
