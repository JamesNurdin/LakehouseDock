/* Goal: Calculate total sales, store returns, web returns, distinct item and page counts per store and brand for the year 2001, applying multiple demographic, product, and promotion filters, using a distinct items CTE, and ranking stores by total sales. */
WITH distinct_items AS (
    SELECT DISTINCT i_item_sk, i_brand
    FROM item
),

sales_agg AS (
    SELECT
        s.s_store_sk               AS s_store_sk,
        s.s_store_name             AS s_store_name,
        di.i_brand                 AS i_brand,
        d.d_year                   AS d_year,
        SUM(ss.ss_ext_sales_price)        AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_returns,
        COUNT(DISTINCT di.i_item_sk)       AS distinct_items_sold,
        SUM(ss.ss_quantity)                AS total_quantity,
        COUNT(DISTINCT r.r_reason_desc)    AS distinct_return_reasons,
        COUNT(DISTINCT wp.wp_type)         AS distinct_page_types
    FROM store_sales ss
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN distinct_items di
        ON ss.ss_item_sk = di.i_item_sk
    INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON d.d_date_sk = wr.wr_returned_date_sk
        AND wr.wr_item_sk = di.i_item_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_page wp
        ON d.d_date_sk = wp.wp_creation_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND cd.cd_gender = 'M'
      AND di.i_brand = 'Brand#24'
      AND s.s_state = 'CA'
      AND ib.ib_upper_bound <= 200000
      AND p.p_discount_active = 'Y'
      AND s.s_closed_date_sk IS NULL
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        di.i_brand,
        d.d_year
)
SELECT
    s_store_sk,
    s_store_name,
    i_brand,
    d_year,
    total_sales,
    total_store_returns,
    total_web_returns,
    distinct_items_sold,
    total_quantity,
    distinct_return_reasons,
    distinct_page_types,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
FROM sales_agg
WHERE total_sales > 0
ORDER BY total_sales DESC
LIMIT 100
