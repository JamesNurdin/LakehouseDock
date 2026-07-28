SELECT DISTINCT ss_store_sk,
                ss_item_sk,
                ss_net_paid_inc_tax,
                ss_ext_tax
FROM tpcds.store_sales
WHERE ss_ext_tax > 10.00
  AND ss_net_paid_inc_tax < 2000.00
LIMIT 100
