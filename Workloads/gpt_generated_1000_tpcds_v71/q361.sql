SELECT
    cp.cp_department,
    hd.hd_buy_potential,
    w.w_city,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM tpcds.catalog_sales cs
INNER JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
INNER JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
INNER JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE cs.cs_wholesale_cost > 30
  AND hd.hd_buy_potential = '1001-5000'
  AND w.w_state = 'CA'
  AND cs.cs_net_paid > (
        SELECT AVG(cs2.cs_net_paid)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_wholesale_cost > 30
      )
GROUP BY
    cp.cp_department,
    hd.hd_buy_potential,
    w.w_city
ORDER BY total_net_paid DESC
LIMIT 100
