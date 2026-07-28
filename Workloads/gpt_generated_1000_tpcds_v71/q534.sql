WITH
  -- Aggregate store returns per store and item
  store_agg AS (
    SELECT
      s.s_store_sk            AS store_sk,
      i.i_item_sk            AS item_sk,
      SUM(sr.sr_return_quantity) AS total_qty,
      SUM(sr.sr_return_amt)      AS total_amt,
      d.d_year               AS return_year,
      hd.hd_buy_potential    AS buy_potential
    FROM store_returns sr
    JOIN store s               ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d            ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i                ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_geography_class = 'Unknown'
      AND d.d_dow IN (1, 2, 3)
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND i.i_current_price > 20
      AND hd.hd_vehicle_count >= 2
    GROUP BY s.s_store_sk, i.i_item_sk, d.d_year, hd.hd_buy_potential
  ),

  -- Aggregate web returns per web page and item
  web_agg AS (
    SELECT
      wp.wp_web_page_sk      AS page_sk,
      i.i_item_sk            AS item_sk,
      SUM(wr.wr_return_quantity) AS total_qty,
      SUM(wr.wr_return_amt)      AS total_amt,
      d.d_year               AS return_year,
      hd.hd_buy_potential    AS buy_potential
    FROM web_returns wr
    JOIN web_page wp          ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d           ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i               ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wp.wp_url LIKE '%example%'
      AND d.d_dow IN (1, 2, 3)
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND i.i_current_price > 20
      AND hd.hd_vehicle_count >= 2
    GROUP BY wp.wp_web_page_sk, i.i_item_sk, d.d_year, hd.hd_buy_potential
  ),

  -- First branch: store channel data
  store_branch AS (
    SELECT
      'store'                     AS channel,
      sa.store_sk                AS entity_id,
      i.i_product_name           AS product_name,
      sa.return_year            AS year,
      sa.buy_potential           AS buy_potential,
      sa.total_qty               AS total_qty,
      sa.total_amt               AS total_amt,
      p.p_promo_id               AS promo_id,
      cr.cr_returned_date_sk     AS cr_date_sk
    FROM store_agg sa
    JOIN item i               ON sa.item_sk = i.i_item_sk
    JOIN promotion p          ON p.p_item_sk = i.i_item_sk
    JOIN date_dim d_start     ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end       ON p.p_end_date_sk   = d_end.d_date_sk
    JOIN catalog_returns cr  ON cr.cr_item_sk = i.i_item_sk
                               AND cr.cr_returned_date_sk = d_start.d_date_sk
    WHERE p.p_channel_tv = 'N'
      AND p.p_discount_active = 'Y'
      AND p.p_channel_details IS NOT NULL
  ),

  -- Second branch: web channel data
  web_branch AS (
    SELECT
      'web'                       AS channel,
      wa.page_sk                 AS entity_id,
      i.i_product_name           AS product_name,
      wa.return_year            AS year,
      wa.buy_potential           AS buy_potential,
      wa.total_qty               AS total_qty,
      wa.total_amt               AS total_amt,
      p.p_promo_id               AS promo_id,
      cr.cr_returned_date_sk     AS cr_date_sk
    FROM web_agg wa
    JOIN item i               ON wa.item_sk = i.i_item_sk
    JOIN promotion p          ON p.p_item_sk = i.i_item_sk
    JOIN date_dim d_start     ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end       ON p.p_end_date_sk   = d_end.d_date_sk
    JOIN catalog_returns cr  ON cr.cr_item_sk = i.i_item_sk
                               AND cr.cr_returned_date_sk = d_start.d_date_sk
    WHERE p.p_channel_tv = 'N'
      AND p.p_discount_active = 'Y'
      AND p.p_channel_details IS NOT NULL
  ),

  -- Union of both channels (distinct rows)
  combined AS (
    SELECT * FROM store_branch
    UNION DISTINCT
    SELECT * FROM web_branch
  )

SELECT
  channel,
  entity_id,
  product_name,
  year,
  buy_potential,
  SUM(total_qty)          AS sum_qty,
  SUM(total_amt)          AS sum_amt,
  COUNT(DISTINCT promo_id) AS promo_count,
  AVG(total_amt)          AS avg_return_amount
FROM combined
GROUP BY channel, entity_id, product_name, year, buy_potential
ORDER BY sum_amt DESC
LIMIT 100
