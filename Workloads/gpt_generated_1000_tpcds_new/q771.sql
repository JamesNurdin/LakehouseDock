WITH
  -- Aggregate return information per item
  returns_agg AS (
    SELECT
      cr.cr_item_sk,
      SUM(cr.cr_return_quantity)        AS total_return_qty,
      SUM(cr.cr_return_amount)          AS total_return_amount,
      COUNT(*)                          AS return_cnt,
      MAX(cr.cr_return_amount)          AS max_return_amount,
      cd.cd_gender                      AS return_customer_gender,
      r.r_reason_desc                   AS return_reason_desc,
      sm.sm_type                        AS return_ship_type,
      sm.sm_code                        AS return_ship_code
    FROM catalog_returns cr
    JOIN item i               ON cr.cr_item_sk     = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r             ON cr.cr_reason_sk   = r.r_reason_sk
    JOIN ship_mode sm         ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910   -- filter 1 (date range surrogate)
      AND cr.cr_return_quantity > 0                        -- filter 2
      AND cr.cr_return_amount   > 10                        -- filter 3
      AND sm.sm_code = 'AIR       '                         -- filter 4 (ship code)
    GROUP BY cr.cr_item_sk, cd.cd_gender, r.r_reason_desc, sm.sm_type, sm.sm_code
  ),

  -- Aggregate sales information per item
  sales_agg AS (
    SELECT
      ws.ws_item_sk,
      SUM(ws.ws_quantity)               AS total_qty,
      SUM(ws.ws_ext_sales_price)        AS total_sales,
      COUNT(*)                          AS sales_cnt,
      cd.cd_gender                      AS sales_customer_gender,
      wp.wp_type                        AS web_page_type,
      sm.sm_type                        AS sales_ship_type,
      p.p_promo_name                    AS promo_name,
      wsit.web_name                     AS site_name,
      MAX(ws.ws_net_profit)             AS max_net_profit
    FROM web_sales ws
    JOIN item i               ON ws.ws_item_sk    = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm         ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p          ON ws.ws_promo_sk    = p.p_promo_sk
    JOIN web_site wsit        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910   -- filter 5 (date range surrogate)
      AND ws.ws_quantity > 0                              -- filter 6
      AND ws.ws_ext_sales_price > 20                      -- filter 7
      AND wp.wp_type = 'content'                          -- filter 8
    GROUP BY ws.ws_item_sk, cd.cd_gender, wp.wp_type, sm.sm_type, p.p_promo_name, wsit.web_name
  ),

  -- Items that appear in BOTH return and sales aggregates
  common_items AS (
    SELECT cr_item_sk FROM returns_agg
    INTERSECT
    SELECT ws_item_sk FROM sales_agg
  )

SELECT
  COALESCE(r.cr_item_sk, s.ws_item_sk)                     AS item_sk,
  r.total_return_qty,
  s.total_qty,
  CASE
    WHEN r.total_return_amount IS NULL THEN 'No Returns'
    WHEN s.total_sales IS NULL          THEN 'No Sales'
    ELSE 'Both Activities'
  END                                                     AS activity_flag,
  r.return_customer_gender,
  s.sales_customer_gender,
  r.return_reason_desc,
  s.promo_name,
  s.site_name,
  ROW_NUMBER() OVER (
    PARTITION BY COALESCE(r.cr_item_sk, s.ws_item_sk)
    ORDER BY COALESCE(r.total_return_amount, 0) DESC
  )                                                       AS rn
FROM returns_agg r
FULL OUTER JOIN sales_agg s
  ON r.cr_item_sk = s.ws_item_sk
WHERE COALESCE(r.cr_item_sk, s.ws_item_sk) IN (SELECT cr_item_sk FROM common_items)
  AND (r.total_return_qty IS NULL OR r.total_return_qty > 5)   -- filter 9
  AND (s.total_qty IS NULL OR s.total_qty > 10)                -- filter 10
  AND (r.return_ship_code = 'AIR       ' OR s.sales_ship_type = 'AIR')
ORDER BY rn
LIMIT 100
