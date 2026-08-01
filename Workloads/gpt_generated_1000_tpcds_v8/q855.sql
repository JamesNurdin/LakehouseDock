WITH
-- Sales facts sampled from store_sales
sales AS (
    SELECT
        ss.ss_item_sk                               AS item_sk,
        d.d_year                                    AS year,
        CAST(SUM(ss.ss_net_paid) AS DECIMAL(12,2))  AS metric,
        COUNT(*)                                    AS cnt
    FROM store_sales AS ss TABLESAMPLE BERNOULLI (10)
    JOIN date_dim AS d      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim AS t      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer AS c      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics AS cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics AS hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY ROLLUP (ss.ss_item_sk, d.d_year)
    HAVING CAST(SUM(ss.ss_net_paid) AS DECIMAL(12,2)) > 1000
),

-- Return facts with both refunded and returning customers (two aliases of CUSTOMER & DEMO tables)
returns AS (
    SELECT
        cr.cr_item_sk                               AS item_sk,
        d_ret.d_year                                AS year,
        CAST(SUM(cr.cr_return_amount) AS DECIMAL(12,2)) AS metric,
        COUNT(*)                                    AS cnt
    FROM catalog_returns AS cr
    JOIN date_dim AS d_ret       ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim AS t_ret       ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN customer AS c_refunded  ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer AS c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_demographics AS cd_refunded  ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics AS cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN household_demographics AS hd_refunded  ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics AS hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN warehouse AS w          ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason AS r             ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY ROLLUP (cr.cr_item_sk, d_ret.d_year)
    HAVING CAST(SUM(cr.cr_return_amount) AS DECIMAL(12,2)) > 500
),

-- Inventory snapshot per item and year
inventory AS (
    SELECT
        i.inv_item_sk                               AS item_sk,
        d_inv.d_year                                AS year,
        CAST(SUM(i.inv_quantity_on_hand) AS DECIMAL(12,2)) AS metric
    FROM inventory AS i
    JOIN date_dim AS d_inv      ON i.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse AS w_inv    ON i.inv_warehouse_sk = w_inv.w_warehouse_sk
    GROUP BY i.inv_item_sk, d_inv.d_year
),

-- Web page activity (using wp_max_ad_count as a surrogate integer key)
web AS (
    SELECT
        wp.wp_max_ad_count                         AS item_sk,
        d_wp.d_year                                AS year,
        CAST(COUNT(*) AS DECIMAL(12,2))           AS metric
    FROM web_page AS wp
    JOIN date_dim AS d_wp       ON wp.wp_creation_date_sk = d_wp.d_date_sk
    JOIN customer AS c_wp       ON wp.wp_customer_sk = c_wp.c_customer_sk
    GROUP BY wp.wp_max_ad_count, d_wp.d_year
)
-- Combine the datasets with set operators
SELECT *
FROM (
    SELECT item_sk, year, metric FROM sales
    UNION
    SELECT item_sk, year, metric FROM returns
) AS u
INTERSECT
SELECT item_sk, year, metric FROM inventory
EXCEPT
SELECT item_sk, year, metric FROM web
LIMIT 100
