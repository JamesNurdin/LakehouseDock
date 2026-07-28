WITH joined AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_county,
    i.i_brand,
    i.i_category,
    t.t_meal_time,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_profit,
    cr.cr_return_tax,
    cr.cr_return_quantity
  FROM catalog_sales cs
  JOIN call_center cc               ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i                        ON cs.cs_item_sk = i.i_item_sk
  JOIN time_dim t                    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN catalog_returns cr           ON cr.cr_order_number = cs.cs_order_number
  WHERE cc.cc_county = 'Fairfield County'
    AND cc.cc_mkt_id = 4
    AND i.i_category = 'Sports'
    AND t.t_meal_time = 'lunch'
    AND cr.cr_return_tax > 10.00
    AND cs.cs_quantity >= 2
)
SELECT
  cc_call_center_id,
  cc_county,
  i_brand,
  i_category,
  t_meal_time,
  SUM(cs_net_profit)          AS total_net_profit,
  SUM(cr_return_tax)          AS total_return_tax,
  COUNT(DISTINCT cs_order_number) AS orders_cnt,
  ROW_NUMBER() OVER (PARTITION BY cc_county ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
FROM joined
GROUP BY
  cc_call_center_id,
  cc_county,
  i_brand,
  i_category,
  t_meal_time
ORDER BY profit_rank
LIMIT 20
