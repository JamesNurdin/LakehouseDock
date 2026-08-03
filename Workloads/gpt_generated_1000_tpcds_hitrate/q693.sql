-- Goal: Analyze store return performance by brand and year, incorporating inventory, promotion, web and warehouse context, and rank brands by net loss.
WITH inv_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_date_sk,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        MAX(inv.inv_quantity_on_hand) AS max_qty
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_date_sk, inv.inv_warehouse_sk
),
agg AS (
    SELECT
        i.i_brand,
        d_ret.d_year,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        COUNT(DISTINCT i.i_item_id) AS distinct_items,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        SUM(inv_agg.total_qty) AS total_inventory_qty
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inv_agg
        ON inv_agg.inv_item_sk = i.i_item_sk
       AND inv_agg.inv_date_sk = d_ret.d_date_sk
    JOIN warehouse w
        ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_start.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    GROUP BY GROUPING SETS ((i.i_brand, d_ret.d_year), (i.i_brand), (d_ret.d_year))
    HAVING SUM(sr.sr_net_loss) > 1000
)
SELECT
    a.i_brand,
    a.d_year,
    a.distinct_tickets,
    a.distinct_items,
    a.total_net_loss,
    a.total_return_inc_tax,
    a.total_inventory_qty,
    RANK() OVER (PARTITION BY a.i_brand ORDER BY a.total_net_loss DESC) AS brand_loss_rank
FROM agg a
ORDER BY a.total_net_loss DESC
LIMIT 100
