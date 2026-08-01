SELECT
  cs_sold_date_sk,
  cs_item_sk,
  cs_quantity,
  cs_net_paid
FROM catalog_sales
WHERE cs_list_price >= 80.00
  AND cs_coupon_amt = 0.00
LIMIT 100
