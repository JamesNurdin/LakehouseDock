WITH agg AS (
    SELECT
        i.i_manufact_id AS manufact_id,
        d.d_year,
        SUM(ss.ss_net_profit) AS sum_store_sales_profit,
        SUM(sr.sr_net_loss) AS sum_store_returns_loss,
        SUM(cr.cr_net_loss) AS sum_catalog_returns_loss,
        SUM(wr.wr_net_loss) AS sum_web_returns_loss,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_units = 'Each'
      AND i.i_manufact_id IN (117, 212, 264)
      AND cc.cc_state = 'CA'
      AND w.w_state = 'CA'
    GROUP BY i.i_manufact_id, d.d_year
)
SELECT
    manufact_id,
    AVG(sum_store_sales_profit) AS avg_store_sales_profit,
    SUM(sum_store_returns_loss) AS total_store_returns_loss,
    SUM(sum_catalog_returns_loss) AS total_catalog_returns_loss,
    SUM(sum_web_returns_loss) AS total_web_returns_loss,
    SUM(total_inventory_quantity) AS total_inventory_quantity
FROM agg
GROUP BY manufact_id
ORDER BY avg_store_sales_profit DESC
LIMIT 100
