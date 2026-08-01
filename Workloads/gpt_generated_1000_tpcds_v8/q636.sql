WITH
  -- Small dimension for cross join
  seq AS (
    SELECT 1 AS dummy UNION ALL SELECT 2
  ),
  -- Filtered dates for reuse
  filtered_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2001 AND 2002
  ),
  -- Subset of items for IN filter and brand selection
  red_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_color = 'Red'
  ),
  brand_items AS (
    SELECT i_item_sk, i_brand
    FROM item
    WHERE i_brand = 'Brand#12'
  )

-- First SELECT (Web Sales side)
SELECT DISTINCT
  ws.ws_order_number AS order_number,
  d.d_year AS date_year,
  bi.i_brand AS brand,
  sm.sm_code AS ship_mode,
  ws.ws_net_paid AS net_value,
  ROW_NUMBER() OVER (PARTITION BY sm.sm_code ORDER BY ws.ws_net_paid DESC) AS rank_val,
  'web_sales' AS source
FROM web_sales ws
JOIN filtered_dates d      ON ws.ws_sold_date_sk = d.d_date_sk
JOIN brand_items bi        ON ws.ws_item_sk = bi.i_item_sk
JOIN ship_mode sm          ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site wsite        ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE wsite.web_state = 'CA'
  AND sm.sm_code = 'AIR'
  AND cd.cd_gender = 'M'
  AND ws.ws_quantity > 0
  AND ws.ws_item_sk IN (SELECT i_item_sk FROM red_items)
  AND EXISTS (SELECT 1 FROM seq)  -- cross join effect (trivial, forces the presence of seq)

UNION DISTINCT

-- Second SELECT (Catalog Returns / Store Returns / Web Returns side)
SELECT DISTINCT
  cr.cr_order_number AS order_number,
  d_ret.d_year AS date_year,
  i.i_brand AS brand,
  sm.sm_code AS ship_mode,
  cr.cr_return_amount AS net_value,
  RANK() OVER (PARTITION BY wsite.web_state ORDER BY cr.cr_net_loss DESC) AS rank_val,
  'catalog_returns' AS source
FROM catalog_returns cr
JOIN catalog_page cp            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i                     ON cr.cr_item_sk = i.i_item_sk
JOIN filtered_dates d_ret      ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN ship_mode sm               ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
LEFT JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
FULL OUTER JOIN store_returns sr
  ON cr.cr_item_sk = sr.sr_item_sk
 AND cr.cr_returned_date_sk = sr.sr_returned_date_sk
JOIN web_returns wr
  ON wr.wr_item_sk = cr.cr_item_sk
 AND wr.wr_returned_date_sk = cr.cr_returned_date_sk
JOIN web_sales ws
  ON ws.ws_item_sk = cr.cr_item_sk
 AND ws.ws_order_number = cr.cr_order_number
JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite             ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE d_ret.d_year = 2001
  AND i.i_current_price > 100
  AND sm.sm_code = 'SEA'
  AND cd_ref.cd_gender = 'F'
  AND cr.cr_item_sk IN (SELECT i_item_sk FROM red_items)
  AND EXISTS (SELECT 1 FROM seq)  -- cross join effect

ORDER BY net_value DESC, rank_val ASC
LIMIT 100
