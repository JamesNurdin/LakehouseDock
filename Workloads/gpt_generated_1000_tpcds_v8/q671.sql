WITH
  agg_store_returns AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_returned_date_sk,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS cnt_returns
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (
      SELECT d_date_sk
      FROM date_dim
      WHERE d_year = 2001
        AND d_month_seq BETWEEN 1 AND 12
    )
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
  ),
  hours_expanded AS (
    SELECT
      cc.cc_call_center_sk,
      TRIM(hour_part) AS hour_part
    FROM call_center cc
    CROSS JOIN UNNEST(split(cc.cc_hours, ',')) AS t(hour_part)
    WHERE cc.cc_hours IS NOT NULL
  )
(
  SELECT
    d.d_year AS d_year,
    agg.total_return_amt AS amount,
    'StoreReturn' AS src,
    i.i_category AS category,
    cd.cd_gender AS gender
  FROM agg_store_returns agg
  JOIN store s ON agg.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON agg.sr_returned_date_sk = d.d_date_sk
  JOIN store_returns sr ON sr.sr_store_sk = agg.sr_store_sk AND sr.sr_returned_date_sk = agg.sr_returned_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND ca.ca_zip = '48930'
    AND hd.hd_vehicle_count >= 1
    AND cd.cd_gender = 'M'
  GROUP BY d.d_year, agg.total_return_amt, i.i_category, cd.cd_gender

  UNION

  SELECT
    d_ret.d_year AS d_year,
    SUM(cr.cr_return_amount) AS amount,
    'CatalogReturn' AS src,
    i.i_category AS category,
    cd.cd_gender AS gender
  FROM catalog_returns cr
  JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE d_ret.d_year = 2001
    AND sm.sm_type = 'AIR'
    AND EXISTS (
      SELECT 1
      FROM hours_expanded he
      WHERE he.cc_call_center_sk = cc.cc_call_center_sk
        AND he.hour_part = '08:00'
    )
  GROUP BY d_ret.d_year, i.i_category, cd.cd_gender

  INTERSECT

  SELECT
    d_sold.d_year AS d_year,
    SUM(ws.ws_net_profit) AS amount,
    'WebSales' AS src,
    i.i_category AS category,
    cd.cd_gender AS gender
  FROM web_sales ws
  JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE d_sold.d_year = 2001
    AND i.i_category = 'Sports'
    AND cd.cd_gender = 'M'
    AND hd.hd_vehicle_count > 0
  GROUP BY d_sold.d_year, i.i_category, cd.cd_gender

  EXCEPT

  SELECT
    d_year,
    amount,
    src,
    category,
    gender
  FROM (
    SELECT
      d.d_year AS d_year,
      agg.total_return_amt AS amount,
      'StoreReturn' AS src,
      i.i_category AS category,
      cd.cd_gender AS gender
    FROM agg_store_returns agg
    JOIN store s ON agg.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON agg.sr_returned_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_store_sk = agg.sr_store_sk AND sr.sr_returned_date_sk = agg.sr_returned_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000  -- different year to create a set to be excluded
    GROUP BY d.d_year, agg.total_return_amt, i.i_category, cd.cd_gender
  ) sub_excl
)
ORDER BY d_year DESC, amount DESC
LIMIT 100
