WITH sampled_sales AS (
  SELECT *
  FROM store_sales
  TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_item_sk,
    ss.ss_hdemo_sk,
    ss.ss_net_paid_inc_tax,
    i.i_brand,
    i.i_category,
    hd.hd_vehicle_count,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    wr.wr_return_amt,
    wr.wr_return_quantity
  FROM sampled_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                              AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                           AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
),
store_high_returns AS (
  SELECT sr.sr_item_sk AS item_sk
  FROM store_returns sr
  WHERE sr.sr_return_amt > 200
),
web_high_returns AS (
  SELECT wr.wr_item_sk AS item_sk
  FROM web_returns wr
  WHERE wr.wr_return_amt > 150
),
intersect_items AS (
  SELECT item_sk FROM store_high_returns
  INTERSECT
  SELECT item_sk FROM web_high_returns
),
union_returns AS (
  SELECT sr.sr_ticket_number AS id, sr.sr_return_amt AS amt
  FROM store_returns sr
  WHERE sr.sr_return_quantity > 0
  UNION
  SELECT wr.wr_order_number AS id, wr.wr_return_amt AS amt
  FROM web_returns wr
  WHERE wr.wr_return_quantity > 0
),
final AS (
  SELECT
    jd.ss_ticket_number,
    jd.ss_item_sk,
    jd.i_brand,
    jd.i_category,
    jd.hd_vehicle_count,
    jd.ss_net_paid_inc_tax,
    jd.sr_return_amt,
    jd.wr_return_amt,
    CASE
      WHEN jd.sr_return_amt > 100 THEN 'High Store Return'
      WHEN jd.wr_return_amt > 100 THEN 'High Web Return'
      ELSE 'Low Returns'
    END AS return_severity,
    ROW_NUMBER() OVER (PARTITION BY jd.i_brand ORDER BY jd.ss_net_paid_inc_tax DESC) AS brand_rank,
    la.avg_return_amt
  FROM joined_data jd
  LEFT JOIN LATERAL (
    SELECT AVG(COALESCE(sr.sr_return_amt, 0) + COALESCE(wr.wr_return_amt, 0)) AS avg_return_amt
    FROM store_returns sr
    JOIN web_returns wr ON wr.wr_item_sk = sr.sr_item_sk
    WHERE sr.sr_item_sk = jd.ss_item_sk
  ) la ON TRUE
  WHERE jd.ss_net_paid_inc_tax > 500
    AND jd.i_brand = 'Brand1'
    AND jd.hd_vehicle_count >= 2
    AND (jd.sr_return_amt IS NOT NULL OR jd.wr_return_amt IS NOT NULL)
    AND jd.ss_item_sk IN (SELECT item_sk FROM intersect_items)
)
SELECT *
FROM final
ORDER BY brand_rank, ss_net_paid_inc_tax DESC
LIMIT 100
