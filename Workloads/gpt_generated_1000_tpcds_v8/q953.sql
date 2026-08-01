WITH
    segment AS (
        SELECT wp.wp_web_page_sk,
               segment
        FROM web_page wp
        CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(segment)
    ),
    agg AS (
        SELECT
            p.p_promo_id,
            ib.ib_income_band_sk,
            td.t_hour,
            SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_loss,
            SUM(ss.ss_net_paid) AS total_paid,
            COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
            COUNT(DISTINCT seg.segment) AS distinct_url_segments
        FROM store_sales ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                             AND sr.sr_item_sk = ss.ss_item_sk
        JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
                         AND ws.ws_promo_sk = p.p_promo_sk
        JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
                             AND wr.wr_order_number = ws.ws_order_number
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        LEFT JOIN segment seg ON wp.wp_web_page_sk = seg.wp_web_page_sk
        WHERE p.p_discount_active = 'Y'
          AND ib.ib_lower_bound >= 30000
          AND td.t_hour BETWEEN 9 AND 17
          AND ws.ws_quantity > 1
          AND wsite.web_mkt_class LIKE '%New%'
        GROUP BY CUBE (p.p_promo_id, ib.ib_income_band_sk, td.t_hour)
    ),
    high_loss AS (
        SELECT DISTINCT p_promo_id FROM agg WHERE total_loss > 1000
    ),
    low_loss AS (
        SELECT DISTINCT p_promo_id FROM agg WHERE total_loss < 200
    ),
    promo_diff AS (
        SELECT p_promo_id FROM high_loss
        EXCEPT
        SELECT p_promo_id FROM low_loss
    )
SELECT
    a.p_promo_id,
    a.ib_income_band_sk,
    a.t_hour,
    a.total_loss,
    a.total_paid,
    a.distinct_url_segments
FROM agg a
WHERE a.p_promo_id IN (SELECT p_promo_id FROM promo_diff)
ORDER BY a.total_loss DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
