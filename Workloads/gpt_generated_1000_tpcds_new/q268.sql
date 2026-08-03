WITH
  -- Aggregate inventory per item/warehouse and collect the dates on which inventory was recorded
  agg_inventory AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty,
      ARRAY_AGG(DISTINCT inv_date_sk) AS date_keys
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  -- Collect promotion ids per item into an array
  promo_per_item AS (
    SELECT
      p_item_sk,
      ARRAY_AGG(p_promo_id) AS promo_ids
    FROM promotion
    GROUP BY p_item_sk
  ),
  -- Customers that have made catalog sales
  catalog_customers AS (
    SELECT DISTINCT cs_bill_customer_sk AS cust_sk FROM catalog_sales
    UNION
    SELECT DISTINCT cs_ship_customer_sk FROM catalog_sales
  ),
  -- Customers that have made store returns
  store_customers AS (
    SELECT DISTINCT sr_customer_sk AS cust_sk FROM store_returns
  ),
  -- Customers that bought something but never returned it in a store (EXCEPT usage)
  customers_excluding AS (
    SELECT cust_sk FROM catalog_customers
    EXCEPT
    SELECT cust_sk FROM store_customers
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_brand,
  d_sold.d_year,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(sr.sr_return_amt) AS total_store_returns,
  SUM(wr.wr_return_amt) AS total_web_returns,
  SUM(ai.total_qty) AS total_inventory_qty,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_returns,
  COUNT(DISTINCT wr.wr_order_number) AS distinct_web_returns
FROM catalog_sales cs
  -- Date of sale and ship dates
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
  -- Item and related dimensions
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  -- Billing and shipping addresses (different aliases)
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  -- Filter to customers that have not returned in a store (EXCEPT set)
  JOIN customers_excluding ce ON cs.cs_bill_customer_sk = ce.cust_sk

  -- Join aggregated inventory and unnest its date array (UNNEST usage)
  LEFT JOIN agg_inventory ai ON cs.cs_item_sk = ai.inv_item_sk AND cs.cs_warehouse_sk = ai.inv_warehouse_sk
  LEFT JOIN LATERAL (
    SELECT date_sk FROM UNNEST(ai.date_keys) AS t(date_sk)
  ) AS ai_dates ON TRUE
  LEFT JOIN date_dim d_inventory ON ai_dates.date_sk = d_inventory.d_date_sk

  -- Join promotion per item and unnest promotion ids (UNNEST usage)
  LEFT JOIN promo_per_item ppi ON i.i_item_sk = ppi.p_item_sk
  LEFT JOIN LATERAL (
    SELECT pid FROM UNNEST(ppi.promo_ids) AS t(pid)
  ) AS promo_ids ON TRUE

  -- Catalog page start/end dates (additional date_dim joins)
  LEFT JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
  LEFT JOIN date_dim d_cp_end   ON cp.cp_end_date_sk   = d_cp_end.d_date_sk

  -- Store returns (joined via item and sale date)
  LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d_sold.d_date_sk
  LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
  LEFT JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk

  -- Web returns (joined via item and sale date)
  LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d_sold.d_date_sk
  LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  LEFT JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
  LEFT JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
  LEFT JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk

  -- Web site (joined through open date)
  LEFT JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
  LEFT JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
  LEFT JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk

GROUP BY
  i.i_item_id,
  i.i_product_name,
  i.i_brand,
  d_sold.d_year
ORDER BY total_sales DESC
LIMIT 100
