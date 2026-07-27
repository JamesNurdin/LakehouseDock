/*
Goal: Analyze sales performance by product category, customer gender, and household buying potential, incorporating return information, a per‑item average return amount (via a scalar subquery), a CASE‑based sales level flag, and a ranking window function.
*/
WITH joined AS (
    SELECT
        ss.ss_sold_date_sk,
        i.i_category,
        i.i_item_sk,
        i.i_item_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        ss.ss_ext_sales_price,
        cr.cr_return_amount,
        cr.cr_return_tax,
        r.r_reason_desc
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
       AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE ss.ss_ext_list_price > 5000
      AND cr.cr_return_tax < 50
      AND hd.hd_buy_potential = '501-1000'
),
agg AS (
    SELECT
        i_category,
        cd_gender,
        hd_buy_potential,
        i_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(*) AS transaction_count,
        MIN(ss_ext_sales_price) AS min_sales_price,
        MAX(ss_ext_sales_price) AS max_sales_price,
        CASE WHEN SUM(ss_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_level,
        (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = i_item_sk
        ) AS avg_item_return_amount
    FROM joined
    GROUP BY i_category, cd_gender, hd_buy_potential, i_item_sk
)
SELECT
    i_category,
    cd_gender,
    hd_buy_potential,
    total_sales,
    total_return_amount,
    avg_return_amount,
    transaction_count,
    min_sales_price,
    max_sales_price,
    sales_level,
    avg_item_return_amount,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
