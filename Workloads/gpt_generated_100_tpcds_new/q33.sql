/*
Goal: Compare brand‑level net revenue and order metrics between catalog sales and store sales, applying several realistic filters, a correlated EXISTS check for returns, a scalar sub‑query comparison, and deduplicating the results across the two data sources.
*/
WITH first_part AS (
    SELECT
        i.i_brand                         AS brand,
        i.i_category                      AS category,
        SUM(cs.cs_net_paid)               AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        AVG(cs.cs_ext_discount_amt)       AS avg_discount,
        MIN(cs.cs_sales_price)            AS min_sales_price,
        MAX(cs.cs_sales_price)            AS max_sales_price
    FROM
        catalog_sales cs
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim td
            ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN web_page wp
            ON wp.wp_customer_sk = c.c_customer_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
    WHERE
        i.i_brand = 'Brand#12'
        AND c.c_birth_year = 1985
        AND cd.cd_credit_rating = 'Good'
        AND hd.hd_buy_potential = '500-1000'
        AND p.p_discount_active = 'Y'
        AND td.t_hour BETWEEN 9 AND 17
        AND cs.cs_sales_price > 50
        AND cs.cs_quantity < (
            SELECT MAX(cs2.cs_quantity)
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = 20230101
        )
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
              AND cr2.cr_return_quantity > 0
        )
    GROUP BY
        i.i_brand,
        i.i_category
    HAVING
        SUM(cs.cs_net_paid) > 1000
),
second_part AS (
    SELECT
        i.i_brand                         AS brand,
        i.i_category                      AS category,
        SUM(ss.ss_net_paid)               AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_orders,
        AVG(ss.ss_ext_discount_amt)       AS avg_discount,
        MIN(ss.ss_sales_price)            AS min_sales_price,
        MAX(ss.ss_sales_price)            AS max_sales_price
    FROM
        store_sales ss
        JOIN time_dim td
            ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN web_page wp
            ON wp.wp_customer_sk = c.c_customer_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_item_sk = i.i_item_sk
    WHERE
        i.i_brand = 'Brand#12'
        AND c.c_birth_year = 1985
        AND cd.cd_credit_rating = 'Good'
        AND hd.hd_buy_potential = '500-1000'
        AND td.t_hour BETWEEN 9 AND 17
        AND ss.ss_sales_price > 50
        AND ss.ss_quantity < (
            SELECT MAX(ss2.ss_quantity)
            FROM store_sales ss2
            WHERE ss2.ss_sold_date_sk = 20230101
        )
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = i.i_item_sk
              AND cr2.cr_return_quantity > 0
        )
    GROUP BY
        i.i_brand,
        i.i_category
    HAVING
        SUM(ss.ss_net_paid) > 1000
)
SELECT
    u.brand,
    u.category,
    SUM(u.total_net_paid)   AS total_net_paid,
    SUM(u.num_orders)       AS total_orders,
    AVG(u.avg_discount)     AS avg_discount,
    MIN(u.min_sales_price)  AS min_sales_price,
    MAX(u.max_sales_price)  AS max_sales_price
FROM (
    SELECT brand, category, total_net_paid, num_orders, avg_discount, min_sales_price, max_sales_price
    FROM first_part
    UNION DISTINCT
    SELECT brand, category, total_net_paid, num_orders, avg_discount, min_sales_price, max_sales_price
    FROM second_part
) u
GROUP BY
    u.brand,
    u.category
ORDER BY
    total_net_paid DESC
LIMIT 100
