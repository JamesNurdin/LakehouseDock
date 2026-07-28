WITH store_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_net_paid_inc_tax) AS store_net_paid_inc_tax
    FROM store_sales
    GROUP BY ss_item_sk, ss_sold_date_sk
)
SELECT
    cp.cp_catalog_page_id,
    i.i_item_id,
    d_sold.d_date,
    SUM(cs.cs_quantity) AS catalog_quantity,
    SUM(cs.cs_net_paid_inc_ship_tax) AS catalog_net_paid_inc_ship_tax,
    sa.store_quantity,
    sa.store_net_paid_inc_tax
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN store_agg sa
    ON sa.ss_item_sk = cs.cs_item_sk
   AND sa.ss_sold_date_sk = cs.cs_sold_date_sk
WHERE d_sold.d_year = 1998
  AND d_sold.d_weekend = 'N'
GROUP BY
    cp.cp_catalog_page_id,
    i.i_item_id,
    d_sold.d_date,
    sa.store_quantity,
    sa.store_net_paid_inc_tax
ORDER BY catalog_net_paid_inc_ship_tax DESC
LIMIT 100
