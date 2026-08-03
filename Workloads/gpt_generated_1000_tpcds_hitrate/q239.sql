WITH base AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        d.d_year,
        i.i_category,
        i.i_current_price,
        hd.hd_income_band_sk,
        ca.ca_state,
        r.r_reason_desc,
        cr.cr_return_quantity AS catalog_return_qty,
        cr.cr_return_amount AS catalog_return_amt,
        cr.cr_net_loss AS catalog_net_loss,
        wr.wr_return_quantity AS web_return_qty,
        wr.wr_return_amt AS web_return_amt,
        wr.wr_net_loss AS web_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss,
        cp.cp_type AS catalog_page_type,
        cc.cc_name AS call_center_name,
        w.w_warehouse_name,
        wp.wp_type AS web_page_type,
        ARRAY['PROMO1','PROMO2'] AS promo_codes
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND i.i_current_price > 100.00
      AND cp.cp_type IN (SELECT DISTINCT wp_sub.wp_type FROM web_page wp_sub WHERE wp_sub.wp_type = 'welcome')
)
SELECT
    b.s_store_name,
    b.d_year,
    u.promo_code,
    SUM(b.sr_return_amt) AS total_store_return_amt,
    SUM(b.catalog_return_amt) AS total_catalog_return_amt,
    SUM(b.web_return_amt) AS total_web_return_amt,
    SUM(b.sr_net_loss + b.catalog_net_loss + b.web_net_loss) AS total_net_loss,
    COUNT(DISTINCT b.i_category) AS distinct_categories,
    AVG(b.i_current_price) AS avg_item_price
FROM base b
CROSS JOIN UNNEST(b.promo_codes) AS u(promo_code)
GROUP BY b.s_store_name, b.d_year, u.promo_code
ORDER BY total_net_loss DESC
LIMIT 100
