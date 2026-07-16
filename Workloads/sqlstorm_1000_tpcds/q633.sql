WITH catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(cs.cs_net_profit) AS catalog_profit,
        MAX(c.cc_name) AS call_center_name
    FROM catalog_sales cs
    LEFT JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk
),
store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        MAX(s.s_store_name) AS store_name
    FROM store_sales ss
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit,
        MAX(wp.wp_url) AS page_url
    FROM web_sales ws
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
unified_sales AS (
    SELECT
        COALESCE(ca.date_sk, sa.date_sk, wa.date_sk) AS date_sk,
        COALESCE(ca.item_sk, sa.item_sk, wa.item_sk) AS item_sk,
        ca.catalog_sales,
        ca.catalog_profit,
        ca.call_center_name,
        sa.store_sales,
        sa.store_profit,
        sa.store_name,
        wa.web_sales,
        wa.web_profit,
        wa.page_url
    FROM catalog_sales_agg ca
    FULL OUTER JOIN store_sales_agg sa
        ON ca.date_sk = sa.date_sk AND ca.item_sk = sa.item_sk
    FULL OUTER JOIN web_sales_agg wa
        ON COALESCE(ca.date_sk, sa.date_sk) = wa.date_sk
        AND COALESCE(ca.item_sk, sa.item_sk) = wa.item_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_item_sk
),
store_returns_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_return_amt) AS store_return_amount,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_return_amt) AS web_return_amount,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
),
unified_returns AS (
    SELECT
        COALESCE(cr.date_sk, sr.date_sk, wr.date_sk) AS date_sk,
        COALESCE(cr.item_sk, sr.item_sk, wr.item_sk) AS item_sk,
        cr.catalog_return_amount,
        cr.catalog_return_cnt,
        sr.store_return_amount,
        sr.store_return_cnt,
        wr.web_return_amount,
        wr.web_return_cnt
    FROM catalog_returns_agg cr
    FULL OUTER JOIN store_returns_agg sr
        ON cr.date_sk = sr.date_sk AND cr.item_sk = sr.item_sk
    FULL OUTER JOIN web_returns_agg wr
        ON COALESCE(cr.date_sk, sr.date_sk) = wr.date_sk
        AND COALESCE(cr.item_sk, sr.item_sk) = wr.item_sk
),
sales_with_returns AS (
    SELECT
        us.date_sk,
        us.item_sk,
        us.catalog_sales,
        us.catalog_profit,
        us.call_center_name,
        us.store_sales,
        us.store_profit,
        us.store_name,
        us.web_sales,
        us.web_profit,
        us.page_url,
        COALESCE(ur.catalog_return_amount, 0) + COALESCE(ur.store_return_amount, 0) + COALESCE(ur.web_return_amount, 0) AS total_return_amount,
        COALESCE(ur.catalog_return_cnt, 0) + COALESCE(ur.store_return_cnt, 0) + COALESCE(ur.web_return_cnt, 0) AS total_return_cnt
    FROM unified_sales us
    LEFT JOIN unified_returns ur
        ON us.date_sk = ur.date_sk AND us.item_sk = ur.item_sk
),
enriched_sales AS (
    SELECT
        swr.*,
        i.i_brand,
        i.i_category,
        i.i_product_name,
        i.i_color,
        i.i_size,
        i.i_units,
        d.d_date
    FROM sales_with_returns swr
    LEFT JOIN item i ON swr.item_sk = i.i_item_sk
    LEFT JOIN date_dim d ON swr.date_sk = d.d_date_sk
),
final_calc AS (
    SELECT
        es.d_date,
        es.item_sk,
        es.i_product_name,
        es.i_brand,
        es.i_category,
        es.catalog_sales,
        es.store_sales,
        es.web_sales,
        es.catalog_profit,
        es.store_profit,
        es.web_profit,
        es.total_return_amount,
        es.total_return_cnt,
        CASE
            WHEN (es.catalog_sales + es.store_sales + es.web_sales) = 0 THEN NULL
            ELSE (es.catalog_profit + es.store_profit + es.web_profit) / (es.catalog_sales + es.store_sales + es.web_sales)
        END AS overall_profit_margin,
        concat('Brand: ', es.i_brand, ', Category: ', es.i_category) AS brand_category,
        row_number() OVER (PARTITION BY es.item_sk ORDER BY es.d_date DESC) AS recent_sales_rank,
        (
            SELECT max(d2.d_date)
            FROM date_dim d2
            JOIN sales_with_returns sw2 ON d2.d_date_sk = sw2.date_sk
            JOIN item i2 ON sw2.item_sk = i2.i_item_sk
            WHERE i2.i_brand = es.i_brand
              AND sw2.item_sk = es.item_sk
              AND d2.d_date < es.d_date
        ) AS prior_brand_sale_date
    FROM enriched_sales es
    WHERE (es.catalog_sales + es.store_sales + es.web_sales) > 1000
      AND (es.i_color IS NOT NULL OR es.i_size LIKE 'L%')
      AND (es.call_center_name IS NOT NULL OR es.store_name IS NOT NULL OR es.page_url IS NOT NULL)
)
SELECT *
FROM final_calc
WHERE recent_sales_rank = 1
ORDER BY overall_profit_margin DESC NULLS LAST
LIMIT 100
