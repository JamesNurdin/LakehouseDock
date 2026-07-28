WITH
base AS (
  SELECT
    d_date.d_year,
    i.i_item_id,
    cc.cc_division,
    SUM(cs.cs_net_paid) AS catalog_sales_net,
    SUM(ss.ss_net_paid) AS store_sales_net,
    SUM(cr.cr_refunded_cash) AS total_refund_cash,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    CASE
      WHEN SUM(cs.cs_net_paid) > 0 THEN SUM(ss.ss_net_paid) / SUM(cs.cs_net_paid)
      ELSE NULL
    END AS store_to_catalog_ratio
  FROM catalog_sales cs
  JOIN date_dim d_date
    ON cs.cs_sold_date_sk = d_date.d_date_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_date_sk = d_date.d_date_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_date.d_date_sk
  WHERE
    cc.cc_division IN (1, 2, 3, 4, 5)
    AND i.i_wholesale_cost BETWEEN 5 AND 50
    AND d_date.d_year BETWEEN 1999 AND 2002
    AND c.c_preferred_cust_flag = 'Y'
    AND ca.ca_country = 'United States'
    AND EXISTS (
      SELECT 1
      FROM web_page wp
      WHERE wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d_date.d_date_sk
    )
  GROUP BY
    d_date.d_year,
    i.i_item_id,
    cc.cc_division
),
final AS (
  SELECT
    d_year,
    cc_division,
    COUNT(DISTINCT i_item_id) AS num_items,
    SUM(catalog_sales_net) AS total_catalog_sales,
    SUM(store_sales_net) AS total_store_sales,
    AVG(store_to_catalog_ratio) AS avg_store_to_catalog_ratio,
    SUM(total_refund_cash) AS total_refund_cash,
    SUM(total_inventory) AS total_inventory
  FROM base
  GROUP BY
    d_year,
    cc_division
  HAVING
    SUM(catalog_sales_net) > 100000
    AND SUM(store_sales_net) > 50000
    AND SUM(total_inventory) > 1000
    AND AVG(store_to_catalog_ratio) > 0.5
    AND COUNT(DISTINCT i_item_id) >= 10
)
SELECT
  d_year,
  cc_division,
  num_items,
  total_catalog_sales,
  total_store_sales,
  avg_store_to_catalog_ratio,
  total_refund_cash,
  total_inventory
FROM final
ORDER BY d_year DESC, total_catalog_sales DESC
LIMIT 100
