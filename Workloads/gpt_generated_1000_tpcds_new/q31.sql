/*
Goal: Analyze sales performance by year and promotion, incorporating related return amounts, inventory on the sale date, and call‑center activity. For each store‑promotion‑year combination we compute total sales, total returns, total inventory, a correlated profit total per store, rank promotions within each year, and assign a global rank. Only rows where the promotion is in the top‑3 for its year are returned.
*/
WITH base AS (
    SELECT
        ss.ss_store_sk,
        d_sales.d_year,
        p.p_promo_name,
        ss.ss_ext_sales_price,
        sr.sr_return_amt,
        inv.inv_quantity_on_hand,
        cd_sales.cd_gender AS sale_gender,
        cd_return.cd_gender AS return_gender,
        cc_closed.cc_name   AS closed_center_name,
        cc_open.cc_name     AS open_center_name
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk                                 -- join rule 1
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk                                          -- join rule 3
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number                              -- join rule 7
       AND sr.sr_item_sk = ss.ss_item_sk                                          -- join rule 5
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk                            -- join rule 4
    JOIN customer_demographics cd_sales
        ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk                                 -- join rule 2
    JOIN customer_demographics cd_return
        ON sr.sr_cdemo_sk = cd_return.cd_demo_sk                                 -- join rule 6
    JOIN inventory inv
        ON d_sales.d_date_sk = inv.inv_date_sk                                    -- join rule 8
    JOIN call_center cc_closed
        ON cc_closed.cc_closed_date_sk = d_return.d_date_sk                       -- join rule 9
    JOIN call_center cc_open
        ON cc_open.cc_open_date_sk = d_sales.d_date_sk                             -- join rule 10
),
aggregated AS (
    SELECT
        b.d_year,
        b.p_promo_name,
        b.ss_store_sk,
        SUM(b.ss_ext_sales_price)   AS total_sales,
        SUM(b.sr_return_amt)        AS total_returns,
        SUM(b.inv_quantity_on_hand) AS total_inventory,
        /* Correlated scalar subquery: total net profit for the store */
        (SELECT SUM(ss2.ss_net_profit)
         FROM store_sales ss2
         WHERE ss2.ss_store_sk = b.ss_store_sk) AS store_total_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(b.ss_ext_sales_price) DESC)            AS global_rank,
        ROW_NUMBER() OVER (PARTITION BY b.d_year ORDER BY SUM(b.ss_ext_sales_price) DESC) AS year_rank
    FROM base b
    GROUP BY
        b.d_year,
        b.p_promo_name,
        b.ss_store_sk
)
SELECT
    a.d_year,
    a.p_promo_name,
    a.ss_store_sk,
    a.total_sales,
    a.total_returns,
    a.total_inventory,
    a.store_total_profit,
    a.global_rank,
    a.year_rank
FROM aggregated a
WHERE a.year_rank <= 3                     -- keep top‑3 promotions per year
ORDER BY a.d_year, a.total_sales DESC
LIMIT 100
