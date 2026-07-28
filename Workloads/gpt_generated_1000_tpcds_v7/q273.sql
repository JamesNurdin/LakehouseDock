WITH sales_by_page AS (
    SELECT
        cp.cp_catalog_page_id AS cp_id,
        d.d_year,
        SUM(cs.cs_net_paid) AS catalog_sales_total,
        SUM(ss.ss_net_paid) AS store_sales_total,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
      AND i.i_brand = 'Brand#12'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '5000-10000'
      AND t.t_meal_time = 'lunch'
      AND p.p_discount_active = 'Y'
    GROUP BY cp.cp_catalog_page_id, d.d_year
)
SELECT
    cp_id,
    AVG(catalog_sales_total) AS avg_catalog_sales,
    AVG(store_sales_total) AS avg_store_sales,
    SUM(order_count) AS total_orders
FROM sales_by_page
GROUP BY cp_id
HAVING AVG(catalog_sales_total) > 1000
ORDER BY avg_catalog_sales DESC
LIMIT 10
