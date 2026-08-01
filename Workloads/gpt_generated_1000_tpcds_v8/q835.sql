-- goal: Identify profitable items sold in 2002 across store and web channels, intersecting items that have both store profit and web return loss, and adding a sampled view of web sales profit. The query deep‑joins all eight TPC‑DS tables, uses multiple aliases, applies a NOT EXISTS anti‑join, samples web_sales with TABLESAMPLE, and combines results with UNION DISTINCT and INTERSECT.
WITH
  -- Store sales enriched with date, customer and promotion information
  ss_join AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_customer_sk,
      ss.ss_item_sk,
      ss.ss_promo_sk,
      ss.ss_net_profit,
      d1.d_year,
      c.c_birth_year,
      p.p_discount_active
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN customer c   ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p  ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d1.d_year = 2002
  ),

  -- Web sales enriched with separate sold‑date and ship‑date dimensions, bill‑customer and promotion
  ws_join AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_ship_date_sk,
      ws.ws_bill_customer_sk,
      ws.ws_item_sk,
      ws.ws_net_profit,
      d_sold.d_year   AS sold_year,
      d_ship.d_year   AS ship_year,
      c_bill.c_birth_year AS bill_birth_year,
      p.p_discount_active
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN promotion p      ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d_sold.d_year = 2002
  ),

  -- Web returns linked to reason, customer and date dimensions
  wr_join AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_return_quantity,
      wr.wr_net_loss,
      d_ret.d_year,
      r.r_reason_desc,
      c_ret.c_birth_year AS refunded_birth_year
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c_ret ON wr.wr_refunded_customer_sk = c_ret.c_customer_sk
    WHERE d_ret.d_year = 2002
  ),

  -- Inventory joined to date and promotion (using promotion start date as the join key)
  inv_join AS (
    SELECT
      i.inv_date_sk,
      i.inv_item_sk,
      i.inv_quantity_on_hand,
      d_inv.d_year,
      p.p_discount_active
    FROM inventory i
    JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
    JOIN promotion p   ON p.p_start_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2002
  ),

  -- Aggregate store‑sales profit per item, excluding items that also have a matching return on the same date (anti‑join)
  agg_a AS (
    SELECT
      sj.ss_item_sk AS item_sk,
      SUM(sj.ss_net_profit) AS metric,
      COUNT(*)               AS cnt
    FROM ss_join sj
    JOIN ws_join wj ON sj.ss_item_sk = wj.ws_item_sk
    WHERE NOT EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_item_sk = sj.ss_item_sk
            AND wr2.wr_returned_date_sk = sj.ss_sold_date_sk
        )
    GROUP BY sj.ss_item_sk
  ),

  -- Aggregate return loss (converted to positive profit) per item where inventory is available
  agg_b AS (
    SELECT
      rj.wr_item_sk AS item_sk,
      -SUM(rj.wr_net_loss) AS metric,
      COUNT(*)           AS cnt
    FROM wr_join rj
    JOIN inv_join ij ON rj.wr_item_sk = ij.inv_item_sk
    WHERE ij.inv_quantity_on_hand > 0
    GROUP BY rj.wr_item_sk
  ),

  -- Sampled web‑sales profit per item (10% Bernoulli sample)
  agg_c AS (
    SELECT
      ws_sample.ws_item_sk AS item_sk,
      SUM(ws_sample.ws_net_profit) AS metric,
      COUNT(*)                     AS cnt
    FROM (
          SELECT ws_item_sk, ws_net_profit
          FROM web_sales
          TABLESAMPLE BERNOULLI (10)
          WHERE ws_sold_date_sk IN (
                SELECT d_date_sk FROM date_dim WHERE d_year = 2002
              )
        ) ws_sample
    GROUP BY ws_sample.ws_item_sk
  )

-- Intersect the first two aggregates, then union with the sampled web‑sales aggregate
SELECT *
FROM (
       SELECT item_sk, metric, cnt FROM agg_a
       INTERSECT
       SELECT item_sk, metric, cnt FROM agg_b
     ) AS intersected
UNION DISTINCT
SELECT item_sk, metric, cnt FROM agg_c
ORDER BY metric DESC
LIMIT 100
