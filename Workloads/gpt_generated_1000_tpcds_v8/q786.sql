WITH
  store_sales_agg AS (
    SELECT
      cd.cd_demo_sk,
      cd.cd_gender,
      SUM(ss.ss_ext_sales_price) AS store_sales_total,
      COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'N'
      AND ss.ss_ext_sales_price > (
        SELECT MAX(p_cost)
        FROM promotion
        WHERE p_channel_tv = 'N'
      )
      AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
      )
    GROUP BY cd.cd_demo_sk, cd.cd_gender
  ),
  web_sales_agg AS (
    SELECT
      cd.cd_demo_sk,
      cd.cd_gender,
      SUM(ws.ws_ext_sales_price) AS web_sales_total,
      COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'N'
      AND ws.ws_ext_sales_price > (
        SELECT MAX(p_cost)
        FROM promotion
        WHERE p_channel_tv = 'N'
      )
    GROUP BY cd.cd_demo_sk, cd.cd_gender
  ),
  common_demo AS (
    SELECT cd_demo_sk FROM store_sales_agg
    INTERSECT
    SELECT cd_demo_sk FROM web_sales_agg
  ),
  union_demo AS (
    SELECT cd_demo_sk, 'store' AS src FROM store_sales_agg
    UNION
    SELECT cd_demo_sk, 'web'   AS src FROM web_sales_agg
  )
SELECT
  COALESCE(ssa.cd_demo_sk, wsa.cd_demo_sk) AS demo_sk,
  COALESCE(ssa.cd_gender, wsa.cd_gender) AS gender,
  ssa.store_sales_total,
  wsa.web_sales_total,
  CASE
    WHEN ssa.store_sales_total IS NULL THEN 'WebOnly'
    WHEN wsa.web_sales_total IS NULL THEN 'StoreOnly'
    ELSE 'Both'
  END AS presence,
  lt.total_quantity
FROM store_sales_agg ssa
FULL OUTER JOIN web_sales_agg wsa
  ON ssa.cd_demo_sk = wsa.cd_demo_sk
CROSS JOIN LATERAL (
  SELECT SUM(ss2.ss_quantity) AS total_quantity
  FROM store_sales ss2
  WHERE ss2.ss_cdemo_sk = COALESCE(ssa.cd_demo_sk, wsa.cd_demo_sk)
    AND ss2.ss_quantity > 5
) lt
WHERE COALESCE(ssa.cd_demo_sk, wsa.cd_demo_sk) IN (SELECT cd_demo_sk FROM common_demo)
ORDER BY demo_sk
LIMIT 100
