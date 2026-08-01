WITH hd_store AS (
  SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    sr.sr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_demo_sk ORDER BY sr.sr_net_loss DESC) AS rn
  FROM tpcds.household_demographics hd
  JOIN tpcds.store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE regexp_like(hd.hd_buy_potential, '^High')
    AND EXISTS (
      SELECT 1
      FROM tpcds.web_returns wr
      WHERE wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_return_tax > 10
    )
),
hd_web AS (
  SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    ws.ws_net_paid_inc_tax,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_demo_sk ORDER BY ws.ws_net_paid_inc_tax DESC) AS rn_ws
  FROM tpcds.household_demographics hd
  JOIN tpcds.web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
  WHERE hd.hd_buy_potential LIKE '%Potential%'
    AND regexp_extract(hd.hd_buy_potential, '(\\d+)$', 1) IS NOT NULL
),
store_keys AS (
  SELECT hd_demo_sk FROM hd_store WHERE rn = 1
),
web_keys AS (
  SELECT hd_demo_sk FROM hd_web WHERE rn_ws = 1
),
union_keys AS (
  SELECT hd_demo_sk FROM store_keys
  UNION
  SELECT hd_demo_sk FROM web_keys
),
intersect_keys AS (
  SELECT hd_demo_sk FROM store_keys
  INTERSECT
  SELECT hd_demo_sk FROM web_keys
),
except_keys AS (
  SELECT hd_demo_sk FROM store_keys
  EXCEPT
  SELECT hd_demo_sk FROM web_keys
)
SELECT *
FROM (
  SELECT 'union' AS set_type, uk.hd_demo_sk FROM union_keys uk
  UNION ALL
  SELECT 'intersect' AS set_type, ik.hd_demo_sk FROM intersect_keys ik
  UNION ALL
  SELECT 'except' AS set_type, ek.hd_demo_sk FROM except_keys ek
) final
ORDER BY set_type
LIMIT 100
