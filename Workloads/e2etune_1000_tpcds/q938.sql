WITH item_returns AS (
  SELECT
    i.i_item_sk,
    i.i_category,
    i.i_brand,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_fee) AS avg_fee,
    SUM(cr.cr_return_quantity) AS total_quantity,
    AVG(cr.cr_return_amount / NULLIF(i.i_current_price, 0)) AS avg_return_price_ratio
  FROM catalog_returns cr
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  WHERE cr.cr_fee >= 20.00
    AND cr.cr_return_amount > 0
    AND cr.cr_call_center_sk IN (7, 31)
    AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY i.i_item_sk, i.i_category, i.i_brand
),
category_brand_agg AS (
  SELECT
    i_category,
    i_brand,
    SUM(return_cnt) AS total_returns,
    SUM(total_return_amount) AS total_return_amount,
    SUM(total_net_loss) AS total_net_loss,
    AVG(avg_fee) AS avg_fee,
    SUM(total_quantity) AS total_quantity,
    AVG(avg_return_price_ratio) AS avg_return_price_ratio
  FROM item_returns
  GROUP BY i_category, i_brand
  HAVING SUM(return_cnt) >= 5
)
SELECT
  i_category,
  i_brand,
  total_returns,
  total_return_amount,
  total_net_loss,
  avg_fee,
  total_quantity,
  avg_return_price_ratio,
  ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rank
FROM category_brand_agg
ORDER BY total_return_amount DESC
LIMIT 20
