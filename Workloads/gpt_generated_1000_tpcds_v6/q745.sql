/*
Goal: Summarize catalog sales for the year 2001 by store, year, customer gender and household buying potential, applying several business filters, excluding sales linked to high‑ad‑count web pages, and ranking stores within each year by total net paid (including shipping). The query uses explicit joins, a semi‑join via EXISTS, a NOT EXISTS anti‑join, GROUPING SETS for subtotals, and a window rank function. Results are ordered and limited to the top 100 rows.
*/
WITH sales_agg AS (
    SELECT
        s.s_store_sk                               AS store_sk,
        s.s_store_name                            AS store_name,
        d.d_year                                  AS year,
        cd.cd_gender                              AS gender,
        hd.hd_buy_potential                       AS buy_potential,
        SUM(cs.cs_net_paid_inc_ship)              AS total_net_paid,
        SUM(cs.cs_quantity)                       AS total_quantity,
        COUNT(*)                                  AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    /* Semi‑join: at least one product‑type web page exists for the sale date */
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk BETWEEN 2 AND 4
      AND s.s_tax_percentage > 0.07
      AND cs.cs_net_paid_inc_ship > 500.00
      AND cs.cs_quantity >= 2
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_creation_date_sk = cs.cs_sold_date_sk
            AND wp.wp_type = 'product'
      )
      /* Anti‑join: exclude sales that have a web page with more than 3 ads on the same date */
      AND NOT EXISTS (
          SELECT 1
          FROM web_page wp2
          WHERE wp2.wp_creation_date_sk = cs.cs_sold_date_sk
            AND wp2.wp_max_ad_count > 3
      )
    GROUP BY GROUPING SETS (
        (s.s_store_sk, s.s_store_name, d.d_year, cd.cd_gender, hd.hd_buy_potential),
        (s.s_store_sk, s.s_store_name, d.d_year, cd.cd_gender),
        (s.s_store_sk, s.s_store_name, d.d_year),
        (s.s_store_sk, s.s_store_name),
        (d.d_year)
    )
)
SELECT
    store_sk,
    store_name,
    year,
    gender,
    buy_potential,
    total_net_paid,
    total_quantity,
    order_cnt,
    RANK() OVER (PARTITION BY year ORDER BY total_net_paid DESC) AS rank_by_sales
FROM sales_agg
ORDER BY year DESC, rank_by_sales
LIMIT 100
