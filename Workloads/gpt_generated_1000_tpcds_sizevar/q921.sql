WITH
  ss AS (
    SELECT
      ss_item_sk,
      ss_hdemo_sk,
      ss_promo_sk,
      ss_quantity,
      ss_net_paid,
      ss_ticket_number
    FROM store_sales
    WHERE ss_quantity > 10
      AND ss_net_paid > 100
      AND ss_sold_date_sk BETWEEN 2451545 AND 2451910  -- approx. 2000-01-01 to 2000-12-31
  ),
  ws AS (
    SELECT
      ws_item_sk,
      ws_bill_hdemo_sk,
      ws_promo_sk,
      ws_quantity,
      ws_net_paid,
      ws_order_number,
      ws_web_page_sk
    FROM web_sales
    WHERE ws_quantity > 10
      AND ws_net_paid > 100
      AND ws_sold_date_sk BETWEEN 2451545 AND 2451910
  ),
  full_join AS (
    SELECT
      COALESCE(ss.ss_item_sk, ws.ws_item_sk)            AS item_sk,
      COALESCE(ss.ss_hdemo_sk, ws.ws_bill_hdemo_sk)    AS hdemo_sk,
      COALESCE(ss.ss_promo_sk, ws.ws_promo_sk)        AS promo_sk,
      ss.ss_quantity                                    AS store_qty,
      ws.ws_quantity                                    AS web_qty,
      ss.ss_net_paid                                    AS store_net,
      ws.ws_net_paid                                    AS web_net,
      ws.ws_order_number                               AS ws_order_number,
      ws.ws_web_page_sk                                 AS ws_web_page_sk
    FROM ss
    FULL OUTER JOIN ws
      ON ss.ss_item_sk = ws.ws_item_sk
     AND ss.ss_hdemo_sk = ws.ws_bill_hdemo_sk
     AND ss.ss_promo_sk = ws.ws_promo_sk
  ),
  base AS (
    SELECT
      fj.*, 
      i.i_current_price,
      p.p_discount_active,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      wp.wp_type,
      (
        SELECT SUM(wr.wr_return_amt)
        FROM web_returns wr
        WHERE wr.wr_item_sk = fj.item_sk
      ) AS total_return_amt
    FROM full_join fj
    JOIN item i               ON i.i_item_sk = fj.item_sk
    JOIN promotion p          ON p.p_promo_sk = fj.promo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = fj.hdemo_sk
    JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_page wp    ON wp.wp_web_page_sk = fj.ws_web_page_sk
    WHERE i.i_manufact_id IN (260, 460)
      AND p.p_channel_radio = 'N'
      AND ib.ib_upper_bound <= 200000
      AND p.p_discount_active = 'Y'
      AND EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_item_sk = fj.item_sk
          AND wr2.wr_return_amt > 0
      )
  ),
  agg_store AS (
    SELECT
      i.i_item_id,
      p.p_promo_id,
      COUNT(*)                                    AS txn_count,
      SUM(b.store_net)                             AS total_store_net,
      SUM(b.web_net)                               AS total_web_net,
      AVG(b.i_current_price)                      AS avg_price,
      MAX(b.total_return_amt)                     AS max_return_amt
    FROM base b
    JOIN item i       ON i.i_item_sk = b.item_sk
    JOIN promotion p  ON p.p_promo_sk = b.promo_sk
    WHERE b.store_qty IS NOT NULL
    GROUP BY i.i_item_id, p.p_promo_id
  ),
  agg_web AS (
    SELECT DISTINCT
      i.i_item_id,
      p.p_promo_id,
      COUNT(*)                                    AS txn_count,
      SUM(b.store_net)                             AS total_store_net,
      SUM(b.web_net)                               AS total_web_net,
      AVG(b.i_current_price)                      AS avg_price,
      MAX(b.total_return_amt)                     AS max_return_amt
    FROM base b
    JOIN item i       ON i.i_item_sk = b.item_sk
    JOIN promotion p  ON p.p_promo_sk = b.promo_sk
    WHERE b.web_qty IS NOT NULL
    GROUP BY i.i_item_id, p.p_promo_id
  )
SELECT
  u.i_item_id,
  u.p_promo_id,
  u.txn_count,
  u.total_store_net,
  u.total_web_net,
  u.avg_price,
  u.max_return_amt
FROM (
  SELECT i_item_id, p_promo_id, txn_count, total_store_net, total_web_net, avg_price, max_return_amt
  FROM agg_store
  UNION DISTINCT
  SELECT i_item_id, p_promo_id, txn_count, total_store_net, total_web_net, avg_price, max_return_amt
  FROM agg_web
) u
ORDER BY u.total_store_net DESC
LIMIT 100
