WITH
  -- Pre‑aggregate store sales to shrink the fact table
  store_agg AS (
    SELECT
      ss_cdemo_sk,
      ss_hdemo_sk,
      SUM(ss_net_profit) AS total_store_profit
    FROM store_sales
    GROUP BY ss_cdemo_sk, ss_hdemo_sk
  ),
  -- Pre‑aggregate web sales (billing side) for the same purpose
  web_agg AS (
    SELECT
      ws_bill_cdemo_sk,
      ws_bill_hdemo_sk,
      SUM(ws_net_profit) AS total_web_profit
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk, ws_bill_hdemo_sk
  )

-- Combine two analytical sub‑queries with UNION ALL
SELECT
  gender,
  marital_status,
  buy_potential,
  total_profit,
  total_return_amount,
  return_cnt,
  avg_refund_amount,
  gender_rank,
  source
FROM (
  -- Store‑sales side (refunded customers)
  SELECT
    cd.cd_gender        AS gender,
    cd.cd_marital_status AS marital_status,
    hd.hd_buy_potential  AS buy_potential,
    s.total_store_profit AS total_profit,
    cr.cr_return_amount_sum AS total_return_amount,
    cr.return_cnt       AS return_cnt,
    (
      SELECT AVG(cr2.cr_return_amount)
      FROM catalog_returns cr2
      WHERE cr2.cr_refunded_cdemo_sk = cd.cd_demo_sk
    )                   AS avg_refund_amount,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cr.cr_return_amount_sum DESC) AS gender_rank,
    'store'             AS source
  FROM store_agg s
  JOIN customer_demographics cd        ON s.ss_cdemo_sk = cd.cd_demo_sk                     -- join 1
  JOIN household_demographics hd      ON s.ss_hdemo_sk = hd.hd_demo_sk                     -- join 2
  JOIN household_demographics hd_extra ON s.ss_hdemo_sk = hd_extra.hd_demo_sk            -- join 3 (extra alias)
  JOIN (
        SELECT
          cr_refunded_cdemo_sk,
          cr_refunded_hdemo_sk,
          SUM(cr_return_amount) AS cr_return_amount_sum,
          COUNT(*) AS return_cnt
        FROM catalog_returns
        GROUP BY cr_refunded_cdemo_sk, cr_refunded_hdemo_sk
      ) cr ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk                                 -- join 4
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk      -- join 5
) AS store_part

UNION ALL

SELECT
  gender,
  marital_status,
  buy_potential,
  total_profit,
  total_return_amount,
  return_cnt,
  avg_refund_amount,
  gender_rank,
  source
FROM (
  -- Web‑sales side (returning customers)
  SELECT
    cd.cd_gender        AS gender,
    cd.cd_marital_status AS marital_status,
    hd.hd_buy_potential  AS buy_potential,
    w.total_web_profit   AS total_profit,
    cr.cr_return_amount_sum AS total_return_amount,
    cr.return_cnt       AS return_cnt,
    (
      SELECT AVG(cr2.cr_return_amount)
      FROM catalog_returns cr2
      WHERE cr2.cr_returning_cdemo_sk = cd.cd_demo_sk
    )                   AS avg_refund_amount,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cr.cr_return_amount_sum DESC) AS gender_rank,
    'web'               AS source
  FROM web_agg w
  JOIN customer_demographics cd        ON w.ws_bill_cdemo_sk = cd.cd_demo_sk                -- join 6
  JOIN household_demographics hd      ON w.ws_bill_hdemo_sk = hd.hd_demo_sk                -- join 7
  JOIN household_demographics hd_extra ON w.ws_bill_hdemo_sk = hd_extra.hd_demo_sk          -- join 8 (extra alias)
  JOIN (
        SELECT
          cr_returning_cdemo_sk,
          cr_returning_hdemo_sk,
          SUM(cr_return_amount) AS cr_return_amount_sum,
          COUNT(*) AS return_cnt
        FROM catalog_returns
        GROUP BY cr_returning_cdemo_sk, cr_returning_hdemo_sk
      ) cr ON cd.cd_demo_sk = cr.cr_returning_cdemo_sk                               -- join 9
  JOIN household_demographics hd_ref ON cr.cr_returning_hdemo_sk = hd_ref.hd_demo_sk      -- join10
) AS web_part

ORDER BY gender_rank, total_profit DESC
