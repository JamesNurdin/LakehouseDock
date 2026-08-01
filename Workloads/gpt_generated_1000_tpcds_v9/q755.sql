WITH
    -- Aggregate store sales with relevant dimensions
    store_sales_agg AS (
        SELECT
            s.s_store_sk,
            s.s_store_id,
            s.s_store_name,
            d_fy.d_fy_year,
            SUM(ss.ss_net_profit) AS store_net_profit,
            SUM(ss.ss_ext_discount_amt) AS store_discount,
            SUM(ss.ss_ext_sales_price) AS store_sales_amount,
            COUNT(*) AS store_sales_cnt
        FROM store_sales ss
        JOIN date_dim d_fy ON ss.ss_sold_date_sk = d_fy.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE d_fy.d_fy_year = 1918
          AND s.s_state = 'CA'
          AND ib.ib_lower_bound >= 50000
          AND p.p_discount_active = 'Y'
        GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, d_fy.d_fy_year
    ),
    -- Aggregate web sales with relevant dimensions
    web_sales_agg AS (
        SELECT
            wsite.web_site_sk,
            wsite.web_site_id,
            d_sold.d_fy_year,
            SUM(ws.ws_net_profit) AS web_net_profit,
            SUM(ws.ws_ext_discount_amt) AS web_discount,
            SUM(ws.ws_ext_sales_price) AS web_sales_amount,
            COUNT(*) AS web_sales_cnt
        FROM web_sales ws
        JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN date_dim d_open ON wsite.web_open_date_sk = d_open.d_date_sk
        WHERE d_sold.d_fy_year = 1918
          AND ib.ib_lower_bound >= 50000
          AND p.p_discount_active = 'Y'
          AND d_open.d_date = DATE '2000-01-01'
        GROUP BY wsite.web_site_sk, wsite.web_site_id, d_sold.d_fy_year
    ),
    -- Aggregate catalog returns with relevant dimensions
    catalog_returns_agg AS (
        SELECT
            d_ret.d_fy_year,
            SUM(cr.cr_net_loss) AS total_return_loss,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM catalog_returns cr
        JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
        JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
        JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE d_ret.d_fy_year = 1918
          AND ib.ib_lower_bound >= 50000
          AND r.r_reason_desc LIKE '%Damaged%'
        GROUP BY d_ret.d_fy_year
    ),
    -- Get distinct active promotions (required DISTINCT usage)
    distinct_promotions AS (
        SELECT DISTINCT p.p_promo_id, p.p_discount_active
        FROM promotion p
        WHERE p.p_discount_active = 'Y'
    )
SELECT
    ssag.s_store_id,
    ssag.s_store_name,
    wsag.web_site_id,
    ssag.d_fy_year AS fiscal_year,
    ssag.store_net_profit,
    wsag.web_net_profit,
    crag.total_return_loss,
    (ssag.store_net_profit + wsag.web_net_profit - COALESCE(crag.total_return_loss, 0)) AS combined_net_profit,
    RANK() OVER (PARTITION BY ssag.d_fy_year ORDER BY (ssag.store_net_profit + wsag.web_net_profit - COALESCE(crag.total_return_loss, 0)) DESC) AS profit_rank,
    SUM(ssag.store_net_profit + wsag.web_net_profit - COALESCE(crag.total_return_loss, 0)) OVER (PARTITION BY ssag.s_store_id ORDER BY ssag.d_fy_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_year_rolling_profit,
    dp.p_discount_active
FROM store_sales_agg ssag
LEFT JOIN web_sales_agg wsag
    ON wsag.d_fy_year = ssag.d_fy_year
LEFT JOIN catalog_returns_agg crag
    ON crag.d_fy_year = ssag.d_fy_year
LEFT JOIN distinct_promotions dp
    ON dp.p_discount_active = 'Y'
ORDER BY ssag.d_fy_year DESC, combined_net_profit DESC
LIMIT 100
