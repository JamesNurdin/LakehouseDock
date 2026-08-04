WITH
  -- Pre‑aggregate inventory (sampled 10% of rows)
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),

  -- Orders that satisfy two different date‑based filters
  order_intersect AS (
    SELECT ws_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_sales_price > 100
    INTERSECT
    SELECT ws_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_quantity >= 2
  )

SELECT
  d.d_year,
  we.web_name,
  r.r_reason_desc,
  SUM(ws.ws_ext_sales_price)               AS total_sales,
  COUNT(DISTINCT ws.ws_order_number)       AS order_cnt,
  COALESCE(SUM(ir.total_qty), 0)           AS total_inventory_qty
FROM web_sales ws
JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site we               ON we.web_open_date_sk = d.d_date_sk
JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer c                ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca       ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr    ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r             ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN inv_agg ir           ON ws.ws_item_sk = ir.inv_item_sk
WHERE d.d_year = 2001                                         -- filter 1
  AND ca.ca_state = 'TX'                                      -- filter 2
  AND hd.hd_income_band_sk = 5                                 -- filter 3
  AND r.r_reason_desc = 'Damaged'                              -- filter 4
  AND ws.ws_sales_price > 100                                 -- filter 5
  AND ws.ws_order_number IN (SELECT ws_order_number FROM order_intersect)
GROUP BY CUBE (d.d_year, we.web_name, r.r_reason_desc)

UNION

SELECT
  d.d_year,
  we.web_name,
  r.r_reason_desc,
  SUM(sr.sr_return_amt + COALESCE(cr.cr_return_amount,0)) AS total_sales,
  COUNT(DISTINCT sr.sr_ticket_number)                     AS order_cnt,
  COALESCE(SUM(ir.total_qty), 0)                         AS total_inventory_qty
FROM store_returns sr
JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
JOIN web_site we               ON we.web_open_date_sk = d.d_date_sk          -- same join rule as above
JOIN reason r                 ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer c                ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca       ON sr.sr_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns cr   ON cr.cr_returned_date_sk = d.d_date_sk
                                AND cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN inv_agg ir           ON sr.sr_item_sk = ir.inv_item_sk
WHERE d.d_year = 2001                                         -- filter 1
  AND ca.ca_state = 'TX'                                      -- filter 2
  AND hd.hd_income_band_sk = 5                                 -- filter 3
  AND r.r_reason_desc = 'Damaged'                              -- filter 4
  AND sr.sr_return_amt > 0                                    -- additional filter
GROUP BY CUBE (d.d_year, we.web_name, r.r_reason_desc)

ORDER BY d_year DESC, total_sales DESC
LIMIT 100
