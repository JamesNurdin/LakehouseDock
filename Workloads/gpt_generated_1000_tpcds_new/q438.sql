WITH
  /* Aggregate catalog sales per item */
  agg_sales_by_item AS (
    SELECT
      cs_item_sk,
      SUM(cs_net_paid) AS total_sales,
      SUM(cs_net_profit) AS total_profit
    FROM
      catalog_sales
    WHERE
      cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY
      cs_item_sk
  ),
  /* Aggregate catalog returns per item */
  agg_returns_by_item AS (
    SELECT
      cr_item_sk,
      SUM(cr_return_amount) AS total_returns,
      SUM(cr_net_loss) AS total_loss
    FROM
      catalog_returns
    WHERE
      cr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY
      cr_item_sk
  ),
  /* Orders that appear in both catalog and web channels */
  intersect_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_sold_date_sk >= 2450000
    INTERSECT
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_sold_date_sk >= 2450000
  ),
  /* Orders that appear only in the catalog channel */
  except_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_sold_date_sk >= 2450000
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_sold_date_sk >= 2450000
  )
SELECT
  cust_bill.c_customer_id,
  addr_bill.ca_state,
  w_cat.w_warehouse_name,
  SUM(sales_item.total_sales) AS total_catalog_sales,
  SUM(returns_item.total_returns) AS total_catalog_returns,
  SUM(ws.ws_net_paid) AS total_web_sales,
  COUNT(DISTINCT r.r_reason_id) AS distinct_return_reasons,
  COUNT(DISTINCT word) AS distinct_reason_words,
  COUNT(DISTINCT i.inv_item_sk) AS distinct_inventory_items
FROM
  catalog_sales cs
  /* Billing dimension */
  JOIN customer cust_bill
    ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
  JOIN customer_address addr_bill
    ON cs.cs_bill_addr_sk = addr_bill.ca_address_sk
  JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN warehouse w_cat
    ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
  /* Shipping dimension (reuse tables with different aliases) */
  JOIN customer cust_ship
    ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
  JOIN customer_address addr_ship
    ON cs.cs_ship_addr_sk = addr_ship.ca_address_sk
  JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  /* Join to pre‑aggregated sales */
  LEFT JOIN agg_sales_by_item sales_item
    ON cs.cs_item_sk = sales_item.cs_item_sk
  /* Join to returns (through item key) */
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
  LEFT JOIN agg_returns_by_item returns_item
    ON cr.cr_item_sk = returns_item.cr_item_sk
  /* Join to reason and unnest its description */
  LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN LATERAL (
    SELECT word
    FROM UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
  ) AS unnested_reason ON true
  /* Join inventory via the warehouse */
  LEFT JOIN inventory i
    ON i.inv_warehouse_sk = w_cat.w_warehouse_sk
  /* Join web sales for the same order (only orders that are in intersect_orders) */
  LEFT JOIN web_sales ws
    ON ws.ws_order_number = cs.cs_order_number
   AND ws.ws_order_number IN (SELECT cs_order_number FROM intersect_orders)
  /* Join to web site */
  LEFT JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  /* Filter to keep only orders that are common to both channels */
  WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
GROUP BY
  cust_bill.c_customer_id,
  addr_bill.ca_state,
  w_cat.w_warehouse_name
HAVING
  SUM(sales_item.total_sales) > 10000
ORDER BY
  total_catalog_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
