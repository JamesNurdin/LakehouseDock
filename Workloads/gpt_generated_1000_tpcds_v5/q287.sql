WITH returns_inventory AS (
    SELECT
        sr.sr_store_sk,
        s.s_manager AS manager,
        w.w_state AS state,
        d_ret.d_year AS year,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_ret.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND s.s_hours = '8AM-8AM'
      AND w.w_state = 'CA'
      AND ws.web_market_manager = 'James Brewer'
    GROUP BY sr.sr_store_sk, s.s_manager, w.w_state, d_ret.d_year
)
SELECT
    manager,
    state,
    year,
    total_net_loss,
    total_inventory_qty,
    distinct_tickets,
    total_net_loss / NULLIF(total_inventory_qty, 0) AS loss_per_inventory
FROM returns_inventory
WHERE total_net_loss > 500
ORDER BY total_net_loss DESC
LIMIT 100
