WITH store_metrics AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_market_desc,
        s.s_company_name,
        SUM(ss.ss_net_profit)                           AS store_sales_profit,
        SUM(cs.cs_net_profit)                           AS catalog_sales_profit,
        SUM(ws.ws_net_profit)                           AS web_sales_profit,
        SUM(sr.sr_net_loss)                             AS store_returns_loss,
        SUM(cr.cr_net_loss)                             AS catalog_returns_loss,
        SUM(wr.wr_net_loss)                             AS web_returns_loss,
        SUM(inv.inv_quantity_on_hand)                   AS total_inventory
    FROM
        date_dim d
        /* store related tables */
        JOIN store s
            ON s.s_closed_date_sk = d.d_date_sk
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN reason r
            ON r.r_reason_sk = sr.sr_reason_sk
        JOIN customer_address ca
            ON ca.ca_address_sk = ss.ss_addr_sk
        /* catalog related tables */
        JOIN catalog_sales cs
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN catalog_returns cr
            ON cr.cr_returned_date_sk = d.d_date_sk
            AND cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
        /* web related tables */
        JOIN web_sales ws
            ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN web_returns wr
            ON wr.wr_returned_date_sk = d.d_date_sk
            AND wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
        JOIN web_page wp
            ON wp.wp_web_page_sk = ws.ws_web_page_sk
        /* other dimension tables */
        JOIN ship_mode sm
            ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
        JOIN call_center cc
            ON cc.cc_closed_date_sk = d.d_date_sk
        JOIN inventory inv
            ON inv.inv_date_sk = d.d_date_sk
    WHERE
        d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
        AND s.s_market_desc LIKE '%Successful%'
        AND sm.sm_carrier = 'UPS'
        AND cc.cc_name = 'North America Call Center'
        AND ca.ca_state = 'CA'
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_market_desc,
        s.s_company_name
)
,
avg_profit AS (
    SELECT AVG(total_profit) AS avg_total_profit FROM (
        SELECT
            (store_sales_profit + catalog_sales_profit + web_sales_profit
             - store_returns_loss - catalog_returns_loss - web_returns_loss) AS total_profit
        FROM store_metrics
    ) t
)
SELECT
    sm.s_store_sk,
    sm.s_store_name,
    sm.s_market_desc,
    sm.s_company_name,
    (sm.store_sales_profit + sm.catalog_sales_profit + sm.web_sales_profit
     - sm.store_returns_loss - sm.catalog_returns_loss - sm.web_returns_loss) AS total_profit,
    sm.total_inventory
FROM store_metrics sm
CROSS JOIN avg_profit ap
WHERE
    (sm.store_sales_profit + sm.catalog_sales_profit + sm.web_sales_profit
     - sm.store_returns_loss - sm.catalog_returns_loss - sm.web_returns_loss) > ap.avg_total_profit
    AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r2 ON r2.r_reason_sk = sr2.sr_reason_sk
        WHERE sr2.sr_store_sk = sm.s_store_sk
          AND r2.r_reason_desc = 'Damaged'
    )
ORDER BY total_profit DESC
LIMIT 100
