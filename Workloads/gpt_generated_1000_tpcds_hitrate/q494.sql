WITH
  sales_agg AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY cc.cc_call_center_sk, cc.cc_name
  ),
  returns_agg AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP BY cc.cc_call_center_sk, cc.cc_name
  ),
  sales_no_returns_keys AS (
    SELECT sa.cc_call_center_sk, sa.cc_name
    FROM sales_agg sa
    EXCEPT
    SELECT ra.cc_call_center_sk, ra.cc_name
    FROM returns_agg ra
  ),
  sales_no_returns AS (
    SELECT sa.cc_call_center_sk,
           sa.cc_name,
           sa.total_profit
    FROM sales_agg sa
    JOIN sales_no_returns_keys k
      ON sa.cc_call_center_sk = k.cc_call_center_sk
     AND sa.cc_name = k.cc_name
  )
SELECT *
FROM (
  -- 1️⃣  Call centers with profit above the overall average (right‑outer join keeps all centers)
  SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    COALESCE(sa.total_profit, 0) AS total_profit
  FROM call_center cc
  RIGHT OUTER JOIN sales_agg sa
    ON cc.cc_call_center_sk = sa.cc_call_center_sk
  WHERE COALESCE(sa.total_profit, 0) > (SELECT avg(cs.cs_net_profit) FROM catalog_sales cs)

  UNION ALL

  -- 2️⃣  Call centers whose returns exceed $10,000 (negative profit to highlight loss)
  SELECT
    ra.cc_call_center_sk,
    ra.cc_name,
    -ra.total_return_amount AS total_profit
  FROM returns_agg ra
  WHERE ra.total_return_amount > 10000

  UNION ALL

  -- 3️⃣  Call centers that have sales but no returns (derived via EXCEPT)
  SELECT
    snr.cc_call_center_sk,
    snr.cc_name,
    snr.total_profit
  FROM sales_no_returns snr
) combined
ORDER BY total_profit DESC
LIMIT 100
