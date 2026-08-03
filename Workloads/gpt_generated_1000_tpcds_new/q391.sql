WITH ws_agg AS (
  SELECT
    ws_item_sk,
    ws_promo_sk,
    ws_bill_hdemo_sk,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
  FROM web_sales
  WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450100
    AND ws_sales_price > 20
    AND ws_ext_discount_amt < 500
    AND ws_quantity > 1
  GROUP BY ws_item_sk, ws_promo_sk, ws_bill_hdemo_sk
),
wr_agg AS (
  SELECT
    wr_item_sk,
    wr_order_number,
    SUM(wr_return_amt) AS total_return_amt,
    SUM(wr_net_loss) AS total_return_loss
  FROM web_returns
  WHERE wr_return_quantity > 0
    AND wr_return_amt > 10
  GROUP BY wr_item_sk, wr_order_number
),
joined AS (
  SELECT
    i.i_item_id,
    i.i_category,
    p.p_promo_id,
    p.p_cost,
    p.p_channel_tv,
    p.p_channel_email,
    p.p_channel_event,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wa.total_sales,
    wa.total_profit,
    ra.total_return_amt
  FROM ws_agg wa
  JOIN web_sales ws
    ON wa.ws_item_sk = ws.ws_item_sk
   AND wa.ws_promo_sk = ws.ws_promo_sk
   AND wa.ws_bill_hdemo_sk = ws.ws_bill_hdemo_sk
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN household_demographics hd
    ON wa.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN wr_agg ra
    ON ws.ws_item_sk = ra.wr_item_sk
   AND ws.ws_order_number = ra.wr_order_number
  WHERE p.p_cost > 500
    AND ib.ib_upper_bound <= 100000
    AND i.i_brand_id IN (1, 2, 3)
    AND wa.total_sales > 0
)
SELECT
  p_promo_id,
  channel_flag,
  SUM(total_sales) AS sum_sales,
  SUM(total_profit) AS sum_profit,
  SUM(total_return_amt) AS sum_return_amount,
  CASE WHEN SUM(total_profit) > 0 THEN 'Positive' ELSE 'NonPositive' END AS profit_flag,
  SUM(CASE WHEN channel_flag = 'Y' THEN 1 ELSE 0 END) AS active_channel_count,
  SUM(hd_vehicle_count) AS sum_vehicle_count,
  SUM(ib_lower_bound) AS sum_income_lower_bound
FROM joined
CROSS JOIN UNNEST(ARRAY[joined.p_channel_tv, joined.p_channel_email, joined.p_channel_event]) AS t(channel_flag)
GROUP BY ROLLUP (p_promo_id, channel_flag)
ORDER BY p_promo_id, channel_flag NULLS LAST
