WITH unified AS (
  SELECT
    c.c_customer_id,
    r.r_reason_desc,
    SUM(wr.wr_return_amt)                AS total_return_amount,
    AVG(i.i_current_price)                AS avg_item_price,
    COUNT(DISTINCT wr.wr_order_number)    AS unique_orders,
    (SELECT COUNT(*) FROM promotion p3 WHERE p3.p_item_sk = i.i_item_sk) AS promo_cnt,
    MAX(pm.max_cost)                      AS max_promo_cost,
    i.i_item_sk
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN promotion p ON p.p_item_sk = i.i_item_sk
  CROSS JOIN LATERAL (
    SELECT max(p2.p_cost) AS max_cost
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
  ) pm
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE c.c_last_review_date IN (2452579, 2452424)
    AND i.i_current_price > 20
    AND p.p_purpose = 'Unknown'
    AND ib.ib_upper_bound <= 130000
  GROUP BY c.c_customer_id, r.r_reason_desc, i.i_item_sk

  UNION

  SELECT
    c.c_customer_id,
    r.r_reason_desc,
    SUM(wr.wr_return_amt)                AS total_return_amount,
    AVG(i.i_current_price)                AS avg_item_price,
    COUNT(DISTINCT wr.wr_order_number)    AS unique_orders,
    (SELECT COUNT(*) FROM promotion p3 WHERE p3.p_item_sk = i.i_item_sk) AS promo_cnt,
    MAX(pm.max_cost)                      AS max_promo_cost,
    i.i_item_sk
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN promotion p ON p.p_item_sk = i.i_item_sk
  CROSS JOIN LATERAL (
    SELECT max(p2.p_cost) AS max_cost
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
  ) pm
  JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE c.c_last_review_date >= 2452424
    AND i.i_current_price BETWEEN 30 AND 100
    AND p.p_channel_event = 'N'
    AND ib.ib_lower_bound >= 50000
  GROUP BY c.c_customer_id, r.r_reason_desc, i.i_item_sk
)
SELECT
  u.c_customer_id,
  u.r_reason_desc,
  u.total_return_amount,
  u.avg_item_price,
  u.unique_orders,
  u.promo_cnt,
  u.max_promo_cost,
  ROW_NUMBER() OVER (PARTITION BY u.c_customer_id ORDER BY u.total_return_amount DESC) AS return_rank
FROM unified u
LIMIT 100
