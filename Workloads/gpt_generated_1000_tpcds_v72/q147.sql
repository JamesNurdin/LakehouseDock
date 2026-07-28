/*
Goal: Compute, for each promotion, the average daily net revenue (sales minus all related losses) across all sales channels, filtering on active mail promotions, weekend‑free dates, specific geography, and ensuring inventory on hand. The query joins all 14 selected tables using only the permitted join keys, aggregates per date/promotion in a CTE, then aggregates again per promotion with a HAVING filter and orders the result.
*/
WITH sales_agg AS (
    SELECT
        ds.d_date                         AS sale_date,
        ds.d_year                         AS sale_year,
        p.p_promo_id                      AS promo_id,
        we.web_site_id                    AS web_site_id,
        SUM(ss.ss_ext_sales_price)        AS store_sales_amount,
        SUM(sr.sr_net_loss)               AS store_return_loss,
        SUM(ws.ws_ext_sales_price)        AS web_sales_amount,
        SUM(wr.wr_net_loss)               AS web_return_loss,
        SUM(cr.cr_net_loss)               AS catalog_return_loss,
        SUM(ss.ss_net_profit)             AS store_net_profit,
        SUM(ws.ws_net_profit)             AS web_net_profit
    FROM store_sales ss
    JOIN date_dim ds        ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN time_dim ts        ON ss.ss_sold_time_sk = ts.t_time_sk
    JOIN household_demographics hd   ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca         ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p                 ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr            ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim dr        ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN time_dim tr        ON sr.sr_return_time_sk = tr.t_time_sk
    JOIN web_sales ws                ON ws.ws_item_sk = ss.ss_item_sk
                                      AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
    JOIN date_dim dws       ON ws.ws_sold_date_sk = dws.d_date_sk
    JOIN time_dim tws       ON ws.ws_sold_time_sk = tws.t_time_sk
    JOIN web_page wp                 ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we                 ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr              ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim drw       ON wr.wr_returned_date_sk = drw.d_date_sk
    JOIN time_dim trw       ON wr.wr_returned_time_sk = trw.t_time_sk
    JOIN catalog_returns cr          ON cr.cr_returned_date_sk = ds.d_date_sk
    JOIN catalog_page cp             ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim dcp_start ON cp.cp_start_date_sk = ds.d_date_sk
    JOIN date_dim dcp_end   ON cp.cp_end_date_sk   = ds.d_date_sk
    JOIN customer_address ca_cr_refunded   ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
    JOIN household_demographics hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
    JOIN customer_address ca_cr_returning  ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
    JOIN household_demographics hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
    WHERE
        p.p_channel_dmail = 'Y'
        AND p.p_discount_active = 'Y'
        AND ds.d_weekend = 'N'
        AND ds.d_dom BETWEEN 10 AND 20
        AND we.web_state = 'CA'
        AND ca.ca_country = 'United States'
        AND EXISTS (
            SELECT 1 FROM inventory i
            WHERE i.inv_item_sk = ss.ss_item_sk
              AND i.inv_date_sk = ds.d_date_sk
              AND i.inv_quantity_on_hand > 0
        )
    GROUP BY
        ds.d_date,
        ds.d_year,
        p.p_promo_id,
        we.web_site_id
)
SELECT
    promo_id,
    AVG(store_sales_amount + web_sales_amount - (store_return_loss + web_return_loss + catalog_return_loss)) AS avg_daily_net
FROM sales_agg
GROUP BY promo_id
HAVING AVG(store_sales_amount + web_sales_amount - (store_return_loss + web_return_loss + catalog_return_loss)) > 1000
ORDER BY avg_daily_net DESC
LIMIT 100
