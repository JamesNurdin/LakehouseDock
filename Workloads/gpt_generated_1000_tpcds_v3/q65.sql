WITH sales_daily AS (
    SELECT
        i.i_item_id,
        d.d_date,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(ss.ss_net_profit) AS store_profit_total,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
        SUM(cs.cs_net_paid) AS catalog_net_paid_total,
        SUM(sr.sr_return_amt) AS store_returns_total,
        MAX(inv.inv_quantity_on_hand) AS inventory_on_hand,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        COUNT(DISTINCT wp.wp_web_page_id) AS web_page_count,
        SUM(ss.ss_ext_sales_price) - SUM(sr.sr_return_amt) AS net_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
       AND ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
       AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c_bill.c_customer_sk
       AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE
        d.d_year = 1999
        AND i.i_current_price BETWEEN 5 AND 10
        AND sm.sm_type = 'AIR'
        AND cd_bill.cd_gender = 'M'
        AND c_bill.c_birth_country = 'JAPAN'
        AND wp.wp_max_ad_count >= 2
        AND p.p_discount_active = 'Y'
    GROUP BY i.i_item_id, d.d_date
)
SELECT
    i_item_id,
    SUM(store_sales_total) AS total_store_sales,
    AVG(catalog_sales_total) AS avg_catalog_sales,
    SUM(net_sales) AS total_net_sales,
    SUM(inventory_on_hand) AS total_inventory,
    SUM(promo_count) AS total_promo_count,
    SUM(web_page_count) AS total_web_page_count
FROM sales_daily
GROUP BY i_item_id
HAVING SUM(net_sales) > 0
ORDER BY total_net_sales DESC
LIMIT 100
