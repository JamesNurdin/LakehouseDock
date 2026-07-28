WITH filtered_items AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_category,
           i.i_current_price,
           cc.cc_name,
           web.web_name,
           inv.inv_quantity_on_hand
    FROM tpcds.item i
    LEFT JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_site web ON ws.ws_web_site_sk = web.web_site_sk
    LEFT JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category, i.i_current_price, cc.cc_name, web.web_name, inv.inv_quantity_on_hand
    HAVING i.i_current_price > 50
       AND inv.inv_quantity_on_hand > 0
),
aggregated_sales AS (
    SELECT i.i_item_sk,
           SUM(ss.ss_ext_sales_price) AS total_store_sales,
           SUM(ss.ss_net_profit)      AS total_store_profit,
           SUM(ws.ws_ext_sales_price) AS total_web_sales,
           SUM(ws.ws_net_profit)      AS total_web_profit,
           SUM(sr.sr_return_amt)      AS total_store_returns,
           SUM(cr.cr_return_amount)   AS total_catalog_returns
    FROM tpcds.item i
    JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
                                 AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
)
SELECT fi.i_item_id,
       fi.i_category,
       fi.i_current_price,
       fi.cc_name,
       fi.web_name,
       fi.inv_quantity_on_hand,
       ag.total_store_sales,
       ag.total_web_sales,
       ag.total_store_returns,
       ag.total_catalog_returns,
       (ag.total_store_sales + ag.total_web_sales - (ag.total_store_returns + ag.total_catalog_returns)) AS net_revenue,
       RANK() OVER (PARTITION BY fi.i_category ORDER BY (ag.total_store_sales + ag.total_web_sales - (ag.total_store_returns + ag.total_catalog_returns)) DESC) AS category_rank
FROM filtered_items fi
JOIN aggregated_sales ag ON ag.i_item_sk = fi.i_item_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.store_returns sr_ex
    JOIN tpcds.reason r_ex ON sr_ex.sr_reason_sk = r_ex.r_reason_sk
    WHERE sr_ex.sr_item_sk = fi.i_item_sk
      AND r_ex.r_reason_desc = 'Damaged'
)
ORDER BY net_revenue DESC
LIMIT 100
