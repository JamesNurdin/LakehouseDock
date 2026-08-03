WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_store_sk, ss_sold_date_sk
),
key_diff AS (
    SELECT sr_ticket_number FROM store_returns
    EXCEPT
    SELECT ss_ticket_number FROM store_sales
)
SELECT
    d.d_year,
    s.s_store_name,
    p.p_promo_name,
    hd.hd_buy_potential,
    COUNT(DISTINCT ss_agg.ss_store_sk) AS distinct_store_sales,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_web_items,
    SUM(ss_agg.total_store_sales) AS sum_store_sales,
    SUM(ws.ws_ext_sales_price) AS sum_web_sales,
    SUM(cr.cr_return_amount) AS sum_catalog_return_amount,
    SUM(wr.wr_return_amt) AS sum_web_return_amount,
    ROW_NUMBER() OVER (ORDER BY SUM(ss_agg.total_store_sales) DESC) AS rn,
    lc.lc_cnt
FROM key_diff kd
JOIN store_returns sr ON sr.sr_ticket_number = kd.sr_ticket_number
JOIN store_sales ss ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN ss_agg ON ss_agg.ss_store_sk = ss.ss_store_sk
    AND ss_agg.ss_sold_date_sk = ss.ss_sold_date_sk
JOIN date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
JOIN time_dim t ON t.t_time_sk = ss.ss_sold_time_sk
JOIN time_dim t_sr ON t_sr.t_time_sk = sr.sr_return_time_sk
JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
JOIN store s ON s.s_store_sk = ss.ss_store_sk
JOIN promotion p ON p.p_promo_sk = ss.ss_promo_sk
LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_item_sk = ss.ss_item_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
LEFT JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_reason_sk = r.r_reason_sk
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS lc_cnt
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = s.s_store_sk
      AND sr2.sr_returned_date_sk = d.d_date_sk
) AS lc
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND hd.hd_income_band_sk = 5
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND r.r_reason_desc = 'Damaged'
GROUP BY
    d.d_year,
    s.s_store_name,
    p.p_promo_name,
    hd.hd_buy_potential,
    lc.lc_cnt
ORDER BY sum_store_sales DESC
LIMIT 100
