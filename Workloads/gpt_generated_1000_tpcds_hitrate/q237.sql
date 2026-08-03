WITH
  inventory_agg AS (
    SELECT inv_item_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_date_sk
  ),
  intersect_items AS (
    SELECT cs_item_sk AS item_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
    UNION ALL
    SELECT ss_item_sk AS item_sk
    FROM store_sales ss
    WHERE ss.ss_quantity > 3
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  d_cs.d_year,
  SUM(cs.cs_ext_sales_price)               AS total_catalog_sales,
  SUM(ss.ss_ext_sales_price)               AS total_store_sales,
  SUM(sr.sr_refunded_cash)                 AS total_refunded_cash,
  AVG(cs.cs_net_profit)                    AS avg_catalog_profit,
  MAX(ib.ib_upper_bound)                   AS max_income_upper_bound,
  COUNT(DISTINCT c.c_customer_id)          AS distinct_customers
FROM store_sales ss
JOIN date_dim d_ss          ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss          ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN item i                 ON ss.ss_item_sk = i.i_item_sk
JOIN customer c             ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr       ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim d_sr          ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr          ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN catalog_sales cs       ON cs.cs_bill_customer_sk = c.c_customer_sk
                               AND cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cs          ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs          ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN call_center cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm           ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr    ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_cr          ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr          ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN inventory_agg ia       ON ia.inv_item_sk = i.i_item_sk
                               AND ia.inv_date_sk = d_cs.d_date_sk
JOIN web_site ws            ON ws.web_open_date_sk = d_cs.d_date_sk
JOIN income_band ib         ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d_cs.d_year = 2001                                     -- filter 1: specific year
  AND i.i_color = 'BLUE'                                      -- filter 2: item colour
  AND ib.ib_upper_bound > 100000                              -- filter 3: income band
  AND cd.cd_gender = 'M'                                      -- additional filter
  AND ss.ss_item_sk IN (
        SELECT i2.i_item_sk
        FROM item i2
        WHERE i2.i_brand_id = 12
      )                                                       -- IN‑subquery filter
  AND cs.cs_ext_sales_price > (
        SELECT MAX(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
      )                                                       -- scalar subquery comparison
  AND i.i_item_sk IN (
        SELECT item_sk FROM (
          SELECT cs.cs_item_sk AS item_sk FROM catalog_sales cs WHERE cs.cs_quantity > 5
          INTERSECT
          SELECT ss.ss_item_sk AS item_sk FROM store_sales ss WHERE ss.ss_quantity > 3
        )
      )                                                       -- INTERSECT subquery filter
GROUP BY i.i_item_id, i.i_product_name, d_cs.d_year
HAVING SUM(cs.cs_ext_sales_price) > 1000
ORDER BY total_catalog_sales DESC
