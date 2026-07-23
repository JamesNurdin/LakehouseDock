/*
Goal: Rank items by combined profit across store and web channels while accounting for returns, categorize profit levels, compare each item's profit to the average item profit, and filter on key dimensions such as year, brand, state, division and shipping cost.
*/
WITH aggregated AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        d.d_year,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(sr.sr_net_loss) AS store_return_loss,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) - SUM(sr.sr_net_loss) - SUM(cr.cr_net_loss) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
        AND s.s_closed_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cc.cc_closed_date_sk = d.d_date_sk
        AND cc.cc_division = 5
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cp.cp_start_date_sk = d.d_date_sk
        AND cp.cp_end_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_ship_date_sk = d.d_date_sk
        AND ws.ws_ext_ship_cost > 500
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        AND wsite.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND i.i_brand = 'Brand#12'
        AND s.s_state = 'CA'
        AND cr.cr_return_quantity > 1
        AND EXISTS (
            SELECT 1 FROM catalog_returns cr3
            WHERE cr3.cr_item_sk = i.i_item_sk
              AND cr3.cr_return_quantity > 0
        )
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        d.d_year
)
SELECT
    a.i_item_id,
    a.i_product_name,
    a.i_category,
    a.i_brand,
    a.d_year,
    a.store_net_paid,
    a.web_net_paid,
    a.store_return_loss,
    a.catalog_return_loss,
    a.total_profit,
    CASE
        WHEN a.total_profit > 100000 THEN 'High'
        WHEN a.total_profit > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    CASE
        WHEN a.total_profit > (
            SELECT avg(item_profit) FROM (
                SELECT i2.i_item_sk,
                       SUM(ss2.ss_net_paid) + SUM(ws2.ws_net_paid) - SUM(sr2.sr_net_loss) - SUM(cr2.cr_net_loss) AS item_profit
                FROM store_sales ss2
                JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
                JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
                JOIN store s2 ON ss2.ss_store_sk = s2.s_store_sk
                JOIN store_returns sr2 ON sr2.sr_ticket_number = ss2.ss_ticket_number
                    AND sr2.sr_item_sk = i2.i_item_sk
                    AND sr2.sr_store_sk = s2.s_store_sk
                    AND sr2.sr_returned_date_sk = d2.d_date_sk
                JOIN catalog_returns cr2 ON cr2.cr_item_sk = i2.i_item_sk
                    AND cr2.cr_returned_date_sk = d2.d_date_sk
                JOIN call_center cc2 ON cr2.cr_call_center_sk = cc2.cc_call_center_sk
                JOIN catalog_page cp2 ON cr2.cr_catalog_page_sk = cp2.cp_catalog_page_sk
                JOIN web_sales ws2 ON ws2.ws_item_sk = i2.i_item_sk
                    AND ws2.ws_sold_date_sk = d2.d_date_sk
                JOIN web_site wsite2 ON ws2.ws_web_site_sk = wsite2.web_site_sk
                WHERE d2.d_year = 2001
                GROUP BY i2.i_item_sk
            ) sub
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS avg_profit_flag,
    ROW_NUMBER() OVER (PARTITION BY a.i_category ORDER BY a.total_profit DESC) AS category_rank
FROM aggregated a
ORDER BY a.total_profit DESC
LIMIT 100
