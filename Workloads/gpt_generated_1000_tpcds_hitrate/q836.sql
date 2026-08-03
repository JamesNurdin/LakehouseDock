WITH filtered_store_sales AS (
    SELECT *
    FROM tpcds.store_sales
    WHERE ss_item_sk IN (
        SELECT i_item_sk FROM tpcds.item WHERE i_brand = 'Brand#12'
    )
),
sampled_inventory AS (
    SELECT *
    FROM tpcds.inventory TABLESAMPLE BERNOULLI (10)
)
SELECT
    d_sold.d_date,
    i.i_brand,
    w_cs.w_county,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT cr.cr_order_number) AS return_count,
    MAX(p_ss.p_cost) AS max_promo_cost_for_sales,
    (SELECT MAX(p_cost) FROM tpcds.promotion) AS overall_max_promo_cost,
    promo_stats.promo_cnt
FROM filtered_store_sales ss
RIGHT JOIN tpcds.date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
LEFT JOIN tpcds.time_dim t_sold
    ON ss.ss_sold_time_sk = t_sold.t_time_sk
LEFT JOIN tpcds.item i
    ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS promo_cnt
    FROM tpcds.promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
) AS promo_stats ON true
LEFT JOIN tpcds.household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
LEFT JOIN tpcds.promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
LEFT JOIN tpcds.catalog_sales cs
    ON ss.ss_item_sk = cs.cs_item_sk
   AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
LEFT JOIN tpcds.date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
LEFT JOIN tpcds.time_dim t_ship
    ON cs.cs_sold_time_sk = t_ship.t_time_sk
LEFT JOIN tpcds.household_demographics hd_cs_bill
    ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
LEFT JOIN tpcds.household_demographics hd_cs_ship
    ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
LEFT JOIN tpcds.warehouse w_cs
    ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
LEFT JOIN tpcds.promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN tpcds.date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
LEFT JOIN tpcds.time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
LEFT JOIN sampled_inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_sold.d_date_sk
WHERE w_cs.w_county IN ('Walker County', 'San Miguel County')
GROUP BY
    d_sold.d_date,
    i.i_brand,
    w_cs.w_county,
    promo_stats.promo_cnt
ORDER BY total_sales DESC
LIMIT 100
