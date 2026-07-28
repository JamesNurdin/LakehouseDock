SELECT cs.cs_order_number,
       cs.cs_net_paid_inc_ship,
       i.i_product_name,
       i.i_manufact
FROM tpcds.catalog_sales cs
JOIN tpcds.item i
  ON cs.cs_item_sk = i.i_item_sk
WHERE cs.cs_net_paid_inc_ship > 2000
  AND i.i_manufact = 'callyable'
ORDER BY cs.cs_net_paid_inc_ship DESC
