WITH sales_agg AS (
    SELECT
        i.i_item_id,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_manager_id IN (11, 18)
      AND w.web_gmt_offset = -5.00
    GROUP BY i.i_item_id, d.d_year
)
SELECT
    s.d_year,
    AVG(s.total_sales) AS avg_total_sales,
    COUNT(DISTINCT s.i_item_id) AS num_items,
    (SELECT COUNT(*) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS active_promo_cnt
FROM sales_agg s
WHERE s.total_sales > 10000
GROUP BY s.d_year
HAVING AVG(s.total_sales) > (SELECT AVG(total_sales) FROM sales_agg)
