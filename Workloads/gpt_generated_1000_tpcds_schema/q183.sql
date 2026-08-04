WITH cc_part AS (
        SELECT d.d_date_sk,
               cc.cc_name
        FROM call_center cc
        JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    ),
    ws_part AS (
        SELECT d.d_date_sk,
               ws.web_name
        FROM web_site ws
        JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    ),
    cc_ws AS (
        SELECT COALESCE(cc_part.d_date_sk, ws_part.d_date_sk) AS d_date_sk,
               cc_part.cc_name,
               ws_part.web_name
        FROM cc_part
        FULL OUTER JOIN ws_part ON cc_part.d_date_sk = ws_part.d_date_sk
    ),
    base AS (
        SELECT
            d.d_year,
            cs.cs_order_number,
            cs.cs_ext_sales_price,
            i.i_category,
            p.p_promo_name,
            cp.cp_catalog_number,
            sr.sr_return_amt,
            wr.wr_return_amt,
            r_sr.r_reason_desc    AS sr_reason,
            r_wr.r_reason_desc    AS wr_reason,
            ib.ib_upper_bound,
            cc_ws.cc_name,
            cc_ws.web_name
        FROM date_dim d
        LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
        LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        LEFT JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN cc_ws ON cc_ws.d_date_sk = d.d_date_sk
        WHERE d.d_year BETWEEN 1998 AND 2000
          AND i.i_brand = 'Brand#45'
          AND cp.cp_catalog_number IN (5, 7, 15)
    )
SELECT
    d_year,
    i_category,
    SUM(cs_ext_sales_price)               AS total_sales,
    AVG(sr_return_amt)                    AS avg_store_return,
    AVG(wr_return_amt)                    AS avg_web_return,
    COUNT(DISTINCT cs_order_number)       AS orders,
    MAX(ib_upper_bound)                   AS max_income_upper
FROM base
WHERE EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_name = base.p_promo_name
          AND p2.p_discount_active = 'Y'
    )
GROUP BY d_year, i_category
HAVING SUM(cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
