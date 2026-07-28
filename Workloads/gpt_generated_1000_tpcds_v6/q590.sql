/*
Goal: Compare store and web sales performance per item for a specific brand and promotional channel in fiscal year 2001, identify which channel generated higher revenue per item, rank items within each brand by store sales, and return the top 100 records.
*/
WITH combined_sales AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_manufact,
        d_ss.d_year AS d_year,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) > SUM(ws.ws_ext_sales_price) THEN 'StoreHigher'
            ELSE 'WebHigher'
        END AS higher_channel
    FROM store_sales ss
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE d_ss.d_year = 2001                                   -- fiscal year filter
      AND d_ss.d_month_seq BETWEEN 1210 AND 1220               -- month‑sequence range filter
      AND d_ss.d_weekend = 'N'                                 -- exclude weekends
      AND i.i_brand = 'Brand#12'                               -- focus on a specific brand
      AND p.p_channel_dmail = 'Y'                              -- promotions sent by dmail
    GROUP BY i.i_item_sk, i.i_brand, i.i_manufact, d_ss.d_year
)
SELECT
    i_item_sk,
    i_brand,
    i_manufact,
    d_year,
    store_sales,
    web_sales,
    higher_channel,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY store_sales DESC) AS brand_store_sales_rank
FROM combined_sales
ORDER BY store_sales DESC
LIMIT 100
