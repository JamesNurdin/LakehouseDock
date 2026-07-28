WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_reason_sk AS catalog_reason_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_store_sk,
        sr.sr_reason_sk AS store_reason_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_web_page_sk,
        wr.wr_reason_sk AS web_reason_sk
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
       AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN store_returns sr
        ON cs.cs_item_sk = sr.sr_item_sk
       AND cs.cs_sold_date_sk = sr.sr_returned_date_sk
    LEFT JOIN web_returns wr
        ON cs.cs_item_sk = wr.wr_item_sk
       AND cs.cs_sold_date_sk = wr.wr_returned_date_sk
),
aggregated AS (
    SELECT
        d.d_year,
        i.i_brand,
        s.s_store_name,
        SUM(b.cs_net_paid) AS total_sales,
        COALESCE(SUM(b.cr_return_amount), 0) +
        COALESCE(SUM(b.sr_return_amt), 0) +
        COALESCE(SUM(b.wr_return_amt), 0) AS total_returns,
        COUNT(DISTINCT b.cs_order_number) AS distinct_orders,
        SUM(b.cs_quantity) AS total_quantity
    FROM base b
    JOIN date_dim d ON b.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON b.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON b.cs_item_sk = i.i_item_sk
    JOIN customer c ON b.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON b.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc ON b.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON b.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON b.cs_promo_sk = p.p_promo_sk
    LEFT JOIN store s ON b.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_cat ON b.catalog_reason_sk = r_cat.r_reason_sk
    LEFT JOIN reason r_store ON b.store_reason_sk = r_store.r_reason_sk
    LEFT JOIN reason r_web ON b.web_reason_sk = r_web.r_reason_sk
    LEFT JOIN web_page wp ON b.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'BLUE'
      AND cc.cc_state = 'CA'
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY GROUPING SETS (
        (d.d_year, i.i_brand, s.s_store_name),
        (d.d_year, i.i_brand),
        (d.d_year)
    )
)
SELECT
    a.d_year,
    a.i_brand,
    a.s_store_name,
    a.total_sales,
    a.total_returns,
    a.distinct_orders,
    a.total_quantity,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank,
    (SELECT AVG(total_sales) FROM aggregated) AS avg_sales_all
FROM aggregated a
WHERE a.total_sales > (SELECT AVG(total_sales) FROM aggregated) * 1.5

UNION ALL

SELECT DISTINCT
    a.d_year,
    a.i_brand,
    NULL AS s_store_name,
    a.total_sales,
    a.total_returns,
    a.distinct_orders,
    a.total_quantity,
    NULL AS sales_rank,
    (SELECT AVG(total_sales) FROM aggregated) AS avg_sales_all
FROM aggregated a
WHERE a.i_brand = 'Brand#45' AND a.total_returns > 1000

ORDER BY d_year, total_sales DESC
LIMIT 100
