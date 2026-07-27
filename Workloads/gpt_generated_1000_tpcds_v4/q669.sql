WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_net_paid_inc_tax) AS total_store_net_paid,
        SUM(ss_net_profit)       AS total_store_profit,
        COUNT(*)                AS store_txn_cnt
    FROM store_sales
    GROUP BY ss_item_sk, ss_sold_date_sk
)
SELECT
    cp.cp_department,
    d_sold.d_year,
    promotion.p_promo_name,
    CASE WHEN promotion.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    SUM(cs.cs_ext_sales_price)   AS total_catalog_sales,
    SUM(cs.cs_ext_discount_amt)  AS total_catalog_discount,
    ss_agg.total_store_net_paid,
    ss_agg.total_store_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    AVG(cs.cs_ext_ship_cost)            AS avg_catalog_ship_cost
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion
    ON cs.cs_promo_sk = promotion.p_promo_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_page_start.d_date_sk
JOIN date_dim d_web_access
    ON wp.wp_access_date_sk = d_web_access.d_date_sk
JOIN ss_agg
    ON ss_agg.ss_item_sk = cs.cs_item_sk
   AND ss_agg.ss_sold_date_sk = cs.cs_sold_date_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss_agg.ss_item_sk
   AND sr.sr_returned_date_sk = ss_agg.ss_sold_date_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
WHERE cs.cs_net_paid_inc_tax > (
    SELECT AVG(cs2.cs_net_paid_inc_tax)
    FROM catalog_sales cs2
    WHERE cs2.cs_sold_date_sk = d_sold.d_date_sk
)
GROUP BY
    cp.cp_department,
    d_sold.d_year,
    promotion.p_promo_name,
    CASE WHEN promotion.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END,
    ss_agg.total_store_net_paid,
    ss_agg.total_store_profit
ORDER BY total_catalog_sales DESC
LIMIT 100
