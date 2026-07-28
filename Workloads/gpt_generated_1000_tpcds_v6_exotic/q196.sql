WITH per_store_promo AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        p.p_promo_id,
        SUM(sr.sr_net_loss)                         AS store_return_net_loss,
        SUM(cr.cr_net_loss)                         AS catalog_return_net_loss,
        SUM(ws.ws_net_profit)                       AS web_sales_net_profit,
        SUM(ws.ws_quantity)                         AS total_web_quantity,
        COUNT(*)                                    AS row_cnt
    FROM
        store s
        /* Shared date dimension – connects many tables */
        JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
        /* Store returns */
        JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
                                 AND sr.sr_returned_date_sk = d.d_date_sk
        /* Household and income information for the store return demographic */
        JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        JOIN income_band ib ON hd_sr.hd_income_band_sk = ib.ib_income_band_sk
        /* Catalog returns and their related dimensions */
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        /* Demographics for the refunded side of the catalog return */
        JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
        /* Web sales and their related dimensions */
        JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
                             AND ws.ws_sold_date_sk = d.d_date_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    WHERE
        d.d_year = 2001                                    -- filter 1: year of activity
        AND ws.ws_quantity > 5                             -- filter 2: sizable sales quantity
        AND p.p_discount_active = 'Y'                      -- filter 3: active discount promotions
        AND w.w_gmt_offset >= -5.00                        -- filter 4: reasonable GMT offset
        AND ib.ib_upper_bound <= 80000                     -- filter 5: income band ceiling
        AND EXISTS (                                          -- subquery predicate
            SELECT 1
            FROM warehouse w2
            WHERE w2.w_city = w.w_city
              AND w2.w_warehouse_sq_ft > 500000
        )
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        p.p_promo_id
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.p_promo_id,
    a.store_return_net_loss,
    a.catalog_return_net_loss,
    a.web_sales_net_profit,
    a.total_web_quantity,
    (a.store_return_net_loss + a.catalog_return_net_loss + a.web_sales_net_profit) AS total_net_loss,
    RANK() OVER (ORDER BY (a.store_return_net_loss + a.catalog_return_net_loss + a.web_sales_net_profit) DESC) AS net_loss_rank,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper_bound
FROM per_store_promo a
WHERE a.total_web_quantity > 10
  AND (a.store_return_net_loss + a.catalog_return_net_loss + a.web_sales_net_profit) > 0
ORDER BY total_net_loss DESC
LIMIT 100
