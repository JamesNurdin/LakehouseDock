WITH cs_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_quantity,
        cs.cs_list_price,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_sales_price,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_list_price BETWEEN 50 AND 200
)
SELECT
    d.d_year,
    i.i_brand,
    sm.sm_type,
    w.w_state,
    cd.cd_gender,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(cs.cs_sales_price) AS min_sales_price,
    MAX(cs.cs_ext_discount_amt) AS max_discount_amt
FROM cs_base cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_return_time_sk = t.t_time_sk
    AND sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND w.w_state = 'CA'
  AND cd.cd_gender = 'M'
  AND sm.sm_type = 'AIR'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY d.d_year, i.i_brand, sm.sm_type, w.w_state, cd.cd_gender
HAVING SUM(cs.cs_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
